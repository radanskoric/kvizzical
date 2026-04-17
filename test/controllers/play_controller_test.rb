require "test_helper"

class PlayControllerTest < ActionDispatch::IntegrationTest
  test "show does not create participant when current_player_user is nil" do
    game = games(:waiting_game)

    assert_no_difference "Participant.count" do
      get play_path(code: game.code)
    end

    assert_response :success
  end

  test "create does not set session token when user is already authenticated" do
    game = games(:waiting_game)
    sign_in_as(users(:alice))

    post play_path(code: game.code), params: { name: "Alice" }

    assert_nil session[:user_session_token]
    assert_redirected_to play_path(code: game.code)
  end
end
