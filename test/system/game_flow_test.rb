require "application_system_test_case"

# These tests require Chrome/Chromium. Skip if not available.
# Run with: bin/rails test:system
class GameFlowTest < ApplicationSystemTestCase
  test "full game flow from home page to game over" do
    game = games(:waiting_game)

    visit root_path
    fill_in "code", with: game.code
    click_button "Join"

    fill_in "name", with: "SystemTestPlayer"
    click_button "Join"

    assert_text "Waiting for the host to start"
  end

  test "waiting player receives the first question when the host starts the game" do
    game = Game.create!(quiz: quizzes(:ruby_trivia))
    first_question = game.quiz.questions.order(:position).first

    Capybara.using_session(:player) do
      visit play_path(code: game.code)
      fill_in "name", with: "Waiting Player"
      click_button "Join"

      assert_text "Welcome, Waiting Player"
      assert_text "Waiting for the host to start"
      assert_no_text first_question.body
      connect_turbo_cable_stream_sources
    end

    Capybara.using_session(:host) do
      sign_in_as(users(:alice))
      visit game_path(game)
      connect_turbo_cable_stream_sources

      click_button "Start Quiz"

      assert_text first_question.body
    end

    Capybara.using_session(:player) do
      assert_text first_question.body
      assert_no_text "Waiting for the host to start"
    end
  end

  test "host waiting view updates when a player joins from another browser session" do
    game = Game.create!(quiz: quizzes(:ruby_trivia))

    Capybara.using_session(:host) do
      sign_in_as(users(:alice))
      visit game_path(game)

      assert_text "PLAYERS JOINED\n0"
      assert_no_text "Waiting Player"
      connect_turbo_cable_stream_sources
    end

    Capybara.using_session(:player) do
      visit play_path(code: game.code)
      fill_in "name", with: "Waiting Player"
      click_button "Join"

      assert_text "Welcome, Waiting Player"
      assert_text "Waiting for the host to start"
    end

    Capybara.using_session(:host) do
      assert_text "Waiting Player"
      assert_text "PLAYERS JOINED\n1"
    end
  end

  test "host active view updates when a player joins from another browser session" do
    game = Game.create!(quiz: quizzes(:ruby_trivia))

    Capybara.using_session(:host) do
      sign_in_as(users(:alice))
      visit game_path(game)
      click_button "Start Quiz"

      assert_text "PLAYERS\n0"
      connect_turbo_cable_stream_sources
      connect_turbo_cable_stream_sources
    end

    Capybara.using_session(:player) do
      visit play_path(code: game.code)
      fill_in "name", with: "Active Player"
      click_button "Join"

      assert_text quizzes(:ruby_trivia).title
    end

    Capybara.using_session(:host) do
      connect_turbo_cable_stream_sources
      assert_text "PLAYERS\n1"
    end
  end

  test "host active view updates when an authenticated player joins from another browser session" do
    game = Game.create!(quiz: quizzes(:ruby_trivia))
    first_question = game.quiz.questions.order(:position).first

    Capybara.using_session(:host) do
      sign_in_as(users(:alice))
      visit game_path(game)
      click_button "Start Quiz"

      assert_text "PLAYERS\n0"
      connect_turbo_cable_stream_sources
      connect_turbo_cable_stream_sources
    end

    Capybara.using_session(:player) do
      sign_in_as(users(:bob))
      visit play_path(code: game.code)

      assert_text first_question.body
    end

    Capybara.using_session(:host) do
      connect_turbo_cable_stream_sources
      assert_text "PLAYERS\n1"
    end
  end
end
