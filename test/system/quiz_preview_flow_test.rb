require "application_system_test_case"

class QuizPreviewFlowTest < ApplicationSystemTestCase
  test "host can see preview link from home page quiz card" do
    quiz = quizzes(:ruby_trivia)

    sign_in_as(users(:alice))
    visit root_path

    assert_link "Preview", href: quiz_preview_path(secret_preview_token: quiz.secret_preview_token)
  end

  test "preview link can be accessed anonymously" do
    quiz = quizzes(:ruby_trivia)

    visit quiz_preview_path(secret_preview_token: quiz.secret_preview_token)

    assert_text quiz.title
    assert_text "This is a preview view of the quiz"
    assert_link "Start Quiz", href: quiz_preview_question_path(secret_preview_token: quiz.secret_preview_token, position: 1)
  end

  test "preview timer advances to answer screen when it expires" do
    quiz = quizzes(:ruby_trivia)
    question = questions(:mvc_question)

    question.update!(time_limit_seconds: 1)

    visit quiz_preview_question_path(secret_preview_token: quiz.secret_preview_token, position: question.position)

    assert_text "What does MVC stand for?"
    assert_current_path quiz_preview_answer_path(secret_preview_token: quiz.secret_preview_token, position: question.position, answer_position: 1), ignore_query: false, wait: 5
    assert_text "Model-View-Controller"
  end
end
