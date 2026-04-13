require "test_helper"

class PlayerGameViewTest < ActionDispatch::IntegrationTest
  setup do
    @game = games(:active_game)
    post play_path(code: @game.code), params: { name: "TestPlayer" }
    follow_redirect!
  end

  test "shows question body when game is active" do
    get play_path(code: @game.code)
    assert_response :success
    assert_select "[data-game-status='active']"
    assert_select "[data-question-body]", text: @game.current_question.body
  end

  test "shows answer buttons for current question" do
    get play_path(code: @game.code)
    @game.current_question.answers.each do |answer|
      assert_select "button", text: answer.body
    end
  end

  test "shows waiting state when game has not started" do
    waiting_game = games(:waiting_game)
    post play_path(code: waiting_game.code), params: { name: "TestPlayer" }
    follow_redirect!

    get play_path(code: waiting_game.code)
    assert_response :success
    assert_select "[data-game-status='waiting']"
  end

  test "shows finished state when game is done" do
    @game.update!(status: :finished, current_question: nil)

    get play_path(code: @game.code)
    assert_response :success
    assert_select "[data-game-status='finished']"
  end
end
