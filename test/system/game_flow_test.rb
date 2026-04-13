require "application_system_test_case"

# These tests require Chrome/Chromium. Skip if not available.
# Run with: bin/rails test:system
class GameFlowTest < ApplicationSystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  test "full game flow from home page to game over" do
    game = games(:waiting_game)

    visit root_path
    fill_in "code", with: game.code
    click_button "Join"

    fill_in "name", with: "SystemTestPlayer"
    click_button "Join"

    assert_text "Waiting for the host to start"
  end
end
