require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "authenticated host sees start and preview buttons for created quiz" do
    quiz = quizzes(:ruby_trivia)
    sign_in_as(users(:alice))

    get root_path

    assert_response :success
    assert_select "div", text: /#{Regexp.escape(quiz.title)}/
    assert_select "a[href=?]", games_path(quiz_id: quiz.id), text: "Start"
    assert_select "a[href=?]", quiz_preview_path(secret_preview_token: quiz.secret_preview_token), text: "Preview"
  end
end
