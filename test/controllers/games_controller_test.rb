require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:alice))
  end

  test "show renders successfully for an authenticated host" do
    game = games(:waiting_game)

    get game_path(game)

    assert_response :success
  end

  test "show redirects unauthenticated requests to login" do
    sign_out

    get game_path(games(:waiting_game))

    assert_redirected_to new_session_path
  end

  test "create builds a game for the selected quiz" do
    quiz = quizzes(:ruby_trivia)

    assert_difference [ "Game.count", "quiz.games.count" ], 1 do
      post games_path, params: { quiz_id: quiz.id }
    end

    created_game = Game.order(:id).last
    assert_redirected_to game_path(created_game)
    assert_equal quiz, created_game.quiz
  end

  test "create redirects unauthenticated users" do
    quiz = quizzes(:ruby_trivia)
    sign_out

    assert_no_difference "Game.count" do
      post games_path, params: { quiz_id: quiz.id }
    end

    assert_redirected_to new_session_path
  end

  test "create returns forbidden for a quiz owned by another user" do
    quiz = quizzes(:ruby_trivia)
    sign_out
    sign_in_as(users(:bob))

    assert_no_difference "Game.count" do
      post games_path, params: { quiz_id: quiz.id }
    end

    assert_response :forbidden
  end

  test "show returns forbidden for a game owned by another user" do
    sign_out
    sign_in_as(users(:bob))

    get game_path(games(:waiting_game))

    assert_response :forbidden
  end

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

  test "start returns forbidden for a game owned by another user" do
    game = games(:waiting_game)
    sign_out
    sign_in_as(users(:bob))

    post start_game_path(game)

    assert_response :forbidden
    game.reload
    assert game.waiting?
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

  test "advance broadcasts game state update" do
    game = games(:active_game)
    game.update!(status: :reviewing, question_opened_at: nil)
    calls = []
    game.define_singleton_method(:broadcast_replace_to) do |*args, **kwargs|
      calls << [ args, kwargs ]
    end

    game.advance!

    assert_operator calls.size, :>=, 1
    assert_equal "game_host_area", calls.first.last[:target]
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

  test "finish_question broadcasts game state update" do
    game = games(:active_game)
    calls = []
    game.define_singleton_method(:broadcast_replace_to) do |*args, **kwargs|
      calls << [ args, kwargs ]
    end

    game.finish_question!

    assert_operator calls.size, :>=, 1
    assert_equal "game_host_area", calls.first.last[:target]
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
