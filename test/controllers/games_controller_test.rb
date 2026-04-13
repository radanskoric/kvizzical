require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "start transitions game from waiting to active and opens first question" do
    game = games(:waiting_game)
    assert game.waiting?

    post start_game_path(game)
    assert_redirected_to game_path(game)

    game.reload
    assert game.active?
    assert_equal game.quiz.questions.order(:position).first, game.current_question
    assert_not_nil game.question_opened_at
  end

  test "start does nothing if game is already active" do
    game = games(:active_game)
    original_question = game.current_question

    post start_game_path(game)
    assert_redirected_to game_path(game)

    game.reload
    assert game.active?
    assert_equal original_question, game.current_question
  end

  test "advance moves to next question" do
    game = games(:active_game)
    first_question = game.current_question
    second_question = game.quiz.questions.order(:position).where("position > ?", first_question.position).first
    game.update!(status: :reviewing, question_opened_at: nil)

    post advance_game_path(game)
    assert_redirected_to game_path(game)

    game.reload
    assert game.active?
    assert_equal second_question, game.current_question
    assert_not_nil game.question_opened_at
  end

  test "advance finishes game when no more questions" do
    game = games(:active_game)
    last_question = game.quiz.questions.order(:position).last
    game.update!(status: :reviewing, current_question: last_question, question_opened_at: nil)

    post advance_game_path(game)
    assert_redirected_to game_path(game)

    game.reload
    assert game.finished?
    assert_nil game.current_question
  end

  test "finish_question transitions active to reviewing" do
    game = games(:active_game)
    question = game.current_question

    post finish_question_game_path(game)
    assert_redirected_to game_path(game)

    game.reload
    assert game.reviewing?
    assert_equal question, game.current_question
    assert_nil game.question_opened_at
  end

  test "finish_question does nothing if game is not active" do
    game = games(:waiting_game)

    post finish_question_game_path(game)
    assert_redirected_to game_path(game)

    game.reload
    assert game.waiting?
  end

  test "advance does nothing if game is waiting" do
    game = games(:waiting_game)

    post advance_game_path(game)
    assert_redirected_to game_path(game)

    game.reload
    assert game.waiting?
  end

  test "advance does nothing if game is finished" do
    game = games(:active_game)
    game.update!(status: :finished, current_question: nil)

    post advance_game_path(game)
    assert_redirected_to game_path(game)

    game.reload
    assert game.finished?
  end
end
