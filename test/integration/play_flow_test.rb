require "test_helper"

class PlayFlowTest < ActionDispatch::IntegrationTest
  test "homepage shows game code input" do
    get root_path
    assert_response :success
    assert_select "input[name='code']"
  end

  test "entering a valid code redirects to play page" do
    get root_path
    assert_response :success

    get play_path(code: games(:waiting_game).code)
    assert_response :success
  end

  test "play page shows name form when no user in session" do
    get play_path(code: games(:waiting_game).code)
    assert_response :success
    assert_select "input[name='name']"
    assert_select "form[action=?]", play_path(code: games(:waiting_game).code)
  end

  test "submitting name creates user and redirects back to play page" do
    game = games(:waiting_game)

    assert_difference "User.count", 1 do
      post play_path(code: game.code), params: { name: "Charlie" }
    end

    assert_redirected_to play_path(code: game.code)
    follow_redirect!
    assert_response :success
    assert_select "input[name='name']", count: 0
  end

  test "play page shows game view when user is in session" do
    game = games(:waiting_game)

    post play_path(code: game.code), params: { name: "Charlie" }
    follow_redirect!

    assert_response :success
    assert_select "[data-game-status]", text: /waiting/i
  end

  test "submitting name creates participant for the game" do
    game = games(:waiting_game)

    assert_difference "Participant.count", 1 do
      post play_path(code: game.code), params: { name: "Charlie" }
    end
  end

  test "returning user sees game view without name form" do
    game = games(:waiting_game)

    post play_path(code: game.code), params: { name: "Charlie" }
    follow_redirect!

    get play_path(code: game.code)
    assert_response :success
    assert_select "input[name='name']", count: 0
  end

  test "invalid game code returns 404" do
    get play_path(code: "XXXXXX")
    assert_response :not_found
  end
end
