require "test_helper"

class QuizPreviewsControllerTest < ActionDispatch::IntegrationTest
  test "start page shows preview intro" do
    quiz = quizzes(:ruby_trivia)

    get quiz_preview_path(secret_preview_token: quiz.secret_preview_token)

    assert_response :success
    assert_select "h1", text: quiz.title
    assert_select "p", text: /preview/i
    assert_select "p", text: /2 questions/
    assert_select "a[href=?]", quiz_preview_question_path(secret_preview_token: quiz.secret_preview_token, position: 1), text: /start quiz/i
  end

  test "question page renders answer links without creating records" do
    quiz = quizzes(:ruby_trivia)
    question = questions(:mvc_question)

    assert_no_difference [ "Game.count", "Participant.count", "Response.count" ] do
      get quiz_preview_question_path(secret_preview_token: quiz.secret_preview_token, position: question.position)
    end

    assert_response :success
    assert_select "[data-preview-status='active']"
    assert_select "[data-question-body]", text: /What does MVC stand for\?/

    question.answers.order(:id).each_with_index do |answer, index|
      assert_select "a[href=?]", quiz_preview_answer_path(secret_preview_token: quiz.secret_preview_token, position: question.position, answer_position: index + 1, answered_index: index + 1), text: answer.body
    end
  end

  test "question page returns not found for an unknown position" do
    quiz = quizzes(:ruby_trivia)

    get quiz_preview_question_path(secret_preview_token: quiz.secret_preview_token, position: 99)

    assert_response :not_found
  end

  test "answer page highlights selected answer from url" do
    quiz = quizzes(:ruby_trivia)
    question = questions(:mvc_question)

    get quiz_preview_answer_path(secret_preview_token: quiz.secret_preview_token, position: question.position, answer_position: 2, answered_index: 2)

    assert_response :success
    assert_select "[data-preview-status='reviewing']"
    assert_select "div", text: /Most Valuable Coder/
    assert_select "div", text: /Model-View-Controller/
    assert_select "a[href=?]", quiz_preview_question_path(secret_preview_token: quiz.secret_preview_token, position: 2), text: /next question/i
  end

  test "answer page without answered index renders unanswered state" do
    quiz = quizzes(:ruby_trivia)
    question = questions(:mvc_question)

    get quiz_preview_answer_path(secret_preview_token: quiz.secret_preview_token, position: question.position, answer_position: 1)

    assert_response :success
    assert_select "[data-preview-status='reviewing']"
    assert_select "p", text: /time ran out|didn't answer|no answer/i
  end

  test "answer page returns not found for an unknown question position" do
    quiz = quizzes(:ruby_trivia)

    get quiz_preview_answer_path(secret_preview_token: quiz.secret_preview_token, position: 99, answer_position: 1)

    assert_response :not_found
  end

  test "answer page returns not found for an invalid answer position" do
    quiz = quizzes(:ruby_trivia)
    question = questions(:mvc_question)

    get quiz_preview_answer_path(secret_preview_token: quiz.secret_preview_token, position: question.position, answer_position: 99)

    assert_response :not_found
  end

  test "last answer page links to end screen" do
    quiz = quizzes(:ruby_trivia)
    question = questions(:gem_question)

    get quiz_preview_answer_path(secret_preview_token: quiz.secret_preview_token, position: question.position, answer_position: 1, answered_index: 1)

    assert_response :success
    assert_select "a[href=?]", quiz_preview_end_path(secret_preview_token: quiz.secret_preview_token), text: /finish preview|end preview|see end/i
  end

  test "end page renders completion state" do
    quiz = quizzes(:ruby_trivia)

    get quiz_preview_end_path(secret_preview_token: quiz.secret_preview_token)

    assert_response :success
    assert_select "h1", text: quiz.title
    assert_select "p", text: /preview complete|thanks for previewing/i
  end

  test "unknown preview token returns not found" do
    get quiz_preview_path(secret_preview_token: "missing-token")

    assert_response :not_found
  end
end
