require "test_helper"

class HostDashboardTest < ActionDispatch::IntegrationTest
  test "shows game code on host dashboard" do
    game = games(:waiting_game)
    get game_path(game)
    assert_response :success
    assert_select "[data-game-code]", text: game.code
  end

  test "shows quiz title" do
    game = games(:waiting_game)
    get game_path(game)
    assert_select "h1", text: game.quiz.title
  end

  test "shows player count" do
    game = games(:active_game)
    get game_path(game)
    assert_select "[data-player-count]", text: /#{game.participants.count}/
  end

  test "shows start button when game is waiting" do
    game = games(:waiting_game)
    get game_path(game)
    assert_select "form[action=?]", start_game_path(game)
    assert_select "button", text: /Start/i
  end

  test "does not show start button when game is active" do
    game = games(:active_game)
    get game_path(game)
    assert_select "form[action=?]", start_game_path(game), count: 0
  end
end
