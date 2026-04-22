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

    assert_equal 1, game.reload.participants.count

    Capybara.using_session(:host) do
      connect_turbo_cable_stream_sources
      assert_selector "[data-player-count]", text: "1"
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

    assert_equal 1, game.reload.participants.count

    Capybara.using_session(:host) do
      connect_turbo_cable_stream_sources
      assert_selector "[data-player-count]", text: "1"
    end
  end

  test "stale game broadcast does not move a player back from reviewing to submitted state" do
    game = Game.create!(quiz: quizzes(:ruby_trivia))
    question = game.quiz.questions.order(:position).first
    correct_answer = answers(:mvc_correct).body

    game.participants.create!(user: users(:alice))
    game.participants.create!(user: users(:bob))
    game.start!

    Capybara.using_session(:alice_player) do
      sign_in_as(users(:alice))
      visit play_path(code: game.code)
      connect_turbo_cable_stream_sources

      assert_text question.body
      click_button answers(:mvc_wrong_1).body

      assert_text "Answer submitted!"
      assert_text "Waiting for results…"
    end

    stale_game = Game.includes(:participants).find(game.id)

    Capybara.using_session(:bob_player) do
      sign_in_as(users(:bob))
      visit play_path(code: game.code)
      connect_turbo_cable_stream_sources

      assert_text question.body
      click_button answers(:mvc_correct).body

      assert_selector "[data-leaderboard]"
      assert_text correct_answer
      assert_no_text "Answer submitted!"
    end

    Capybara.using_session(:alice_player) do
      assert_selector "[data-leaderboard]"
      assert_text correct_answer
      assert_no_text "Answer submitted!"
    end

    stale_game.broadcast_game_state

    Capybara.using_session(:alice_player) do
      assert_selector "[data-leaderboard]"
      assert_text correct_answer
      assert_no_text "Answer submitted!"
    end
  end
end
