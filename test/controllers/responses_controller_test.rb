require "test_helper"

class ResponsesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game = games(:active_game)
    @question = @game.current_question
    @correct_answer = answers(:mvc_correct)
    @wrong_answer = answers(:mvc_wrong_1)

    post play_path(code: @game.code), params: { name: "Responder" }
    follow_redirect!
    @game.reload
  end

  test "creates a response for the current question" do
    assert_difference "Response.count", 1 do
      post responses_path, params: {
        game_code: @game.code,
        question_id: @question.id,
        answer_id: @correct_answer.id
      }
    end

    assert_redirected_to play_path(code: @game.code)
  end

  test "finishes the question when all players have answered" do
    game = Game.create!(quiz: quizzes(:ruby_trivia))
    post play_path(code: game.code), params: { name: "Solo Responder" }
    game.reload
    game.start!

    post responses_path, params: {
      game_code: game.code,
      question_id: game.current_question.id,
      answer_id: answers(:mvc_correct).id
    }

    game.reload
    assert game.reviewing?
    assert_nil game.question_opened_at
  end

  test "rejects duplicate response for same question" do
    post responses_path, params: {
      game_code: @game.code,
      question_id: @question.id,
      answer_id: @correct_answer.id
    }

    assert_no_difference "Response.count" do
      post responses_path, params: {
        game_code: @game.code,
        question_id: @question.id,
        answer_id: @wrong_answer.id
      }
    end

    assert_redirected_to play_path(code: @game.code)
  end

  test "rejects response when game is not active" do
    @game.update!(status: :waiting, current_question: nil)

    assert_no_difference "Response.count" do
      post responses_path, params: {
        game_code: @game.code,
        question_id: @question.id,
        answer_id: @correct_answer.id
      }
    end

    assert_redirected_to play_path(code: @game.code)
  end

  test "rejects response past deadline" do
    @game.update!(question_opened_at: 1.hour.ago)

    assert_no_difference "Response.count" do
      post responses_path, params: {
        game_code: @game.code,
        question_id: @question.id,
        answer_id: @correct_answer.id
      }
    end

    assert_redirected_to play_path(code: @game.code)
  end

  test "rejects response when question has no opened at timestamp" do
    @game.update!(question_opened_at: nil)

    assert_no_difference "Response.count" do
      post responses_path, params: {
        game_code: @game.code,
        question_id: @question.id,
        answer_id: @correct_answer.id
      }
    end

    assert_redirected_to play_path(code: @game.code)
  end

  test "rejects response when question id is invalid" do
    assert_no_difference "Response.count" do
      post responses_path, params: {
        game_code: @game.code,
        question_id: -1,
        answer_id: @correct_answer.id
      }
    end

    assert_redirected_to play_path(code: @game.code)
  end

  test "rejects response when participant does not exist" do
    game = Game.create!(quiz: quizzes(:ruby_trivia))
    game.start!

    assert_no_difference "Response.count" do
      post responses_path, params: {
        game_code: game.code,
        question_id: game.current_question.id,
        answer_id: answers(:mvc_correct).id
      }
    end

    assert_redirected_to play_path(code: game.code)
  end

  test "rejects response when save fails due to validation" do
    post responses_path, params: {
      game_code: @game.code,
      question_id: @question.id,
      answer_id: @correct_answer.id
    }

    assert_no_difference "Response.count" do
      post responses_path, params: {
        game_code: @game.code,
        question_id: @question.id,
        answer_id: @correct_answer.id
      }
    end

    assert_redirected_to play_path(code: @game.code)
  end
end
