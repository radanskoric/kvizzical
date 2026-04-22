require "cgi"
require "application_system_test_case"

class SmokeTest < ApplicationSystemTestCase
  setup do
    @host = users(:alice)
    @player_names = [ "Player 1", "Player 2", "Player 3", "Player 4", "Player 5" ]
    @quiz = create_smoke_quiz!
    @game = @quiz.games.create!
  end

  test "five players can play through the multiplayer quiz flow" do
    host_opens_waiting_room
    players_join_waiting_room
    host_sees_joined_players
    host_starts_quiz
    players_see_first_question

    play_question_in_two_one_two_blocks(@quiz.questions.first, [ 0, 1 ], 2, [ 3, 4 ])

    advance_host_to_next_question(@quiz.questions.first, @quiz.questions.second)
    players_see_question(@quiz.questions.second)
    play_question_in_two_one_two_blocks(@quiz.questions.second, [ 1, 2 ], 3, [ 0, 4 ])

    advance_host_to_next_question(@quiz.questions.second, @quiz.questions.third)
    players_see_question(@quiz.questions.third)
    play_question_in_two_one_two_blocks(@quiz.questions.third, [ 2, 4 ], 0, [ 1, 3 ])

    @quiz.questions.offset(3).each_with_index do |question, index|
      advance_host_to_next_question(@quiz.questions[index + 2], question)
      players_see_question(question)
      play_question_with_all_players_answering_rapidly(question)
    end

    finish_quiz_from_last_review_screen(@quiz.questions.last)
  end

  private

    def create_smoke_quiz!
      quiz = @host.created_quizzes.create!(title: "Smoke Test Quiz #{SecureRandom.hex(4)}")

      questions_data = [
        {
          body: "What does MVC stand for?",
          time_limit_seconds: 15,
          answers: [
            { body: "Model-View-Controller", correct: true },
            { body: "Most Valuable Coder", correct: false },
            { body: "Multiple Virtual Connections", correct: false },
            { body: "Main Visual Component", correct: false }
          ]
        },
        {
          body: "Which command starts a Rails console?",
          time_limit_seconds: 15,
          answers: [
            { body: "bin/rails console", correct: true },
            { body: "bin/rails start", correct: false },
            { body: "ruby console", correct: false },
            { body: "bundle exec irb", correct: false }
          ]
        },
        {
          body: "What is the default database for a new Rails 8 app?",
          time_limit_seconds: 15,
          answers: [
            { body: "SQLite3", correct: true },
            { body: "PostgreSQL", correct: false },
            { body: "MySQL", correct: false },
            { body: "MongoDB", correct: false }
          ]
        },
        {
          body: "Which Ruby keyword defines a block that always executes?",
          time_limit_seconds: 15,
          answers: [
            { body: "ensure", correct: true },
            { body: "finally", correct: false },
            { body: "always", correct: false },
            { body: "rescue", correct: false }
          ]
        },
        {
          body: "What does 'DRY' stand for in software development?",
          time_limit_seconds: 15,
          answers: [
            { body: "Don't Repeat Yourself", correct: true },
            { body: "Do Rewrite Yearly", correct: false },
            { body: "Data Runs Yielded", correct: false },
            { body: "Deploy, Refactor, Yolo", correct: false }
          ]
        },
        {
          body: "Which Hotwire library intercepts links and form submissions?",
          time_limit_seconds: 15,
          answers: [
            { body: "Turbo Drive", correct: true },
            { body: "Stimulus", correct: false },
            { body: "Turbo Frames", correct: false },
            { body: "ActionCable", correct: false }
          ]
        },
        {
          body: "What symbol is used for string interpolation in Ruby?",
          time_limit_seconds: 15,
          answers: [
            { body: '#{...}', correct: true },
            { body: "${...}", correct: false },
            { body: "%{...}", correct: false },
            { body: "@{...}", correct: false }
          ]
        },
        {
          body: "Which method makes an ActiveRecord query lazy?",
          time_limit_seconds: 15,
          answers: [
            { body: "where", correct: true },
            { body: "find", correct: false },
            { body: "first", correct: false },
            { body: "count", correct: false }
          ]
        }
      ]

      questions_data.each_with_index do |question_data, index|
        question = quiz.questions.create!(
          body: question_data[:body],
          time_limit_seconds: question_data[:time_limit_seconds],
          position: index + 1
        )

        question_data[:answers].each do |answer_data|
          question.answers.create!(body: answer_data[:body], correct: answer_data[:correct])
        end
      end

      quiz.reload
    end

    def host_opens_waiting_room
      Capybara.using_session(:host) do
        sign_in_as(@host)
        visit game_path(@game)

        assert_text @game.code
        assert_text "PLAYERS JOINED"
        assert_text "0"

        connect_turbo_cable_stream_sources
      end
    end

    def players_join_waiting_room
      @player_names.each_with_index do |name, index|
        Capybara.using_session(player_session(index)) do
          visit play_path(code: @game.code)
          fill_in "name", with: name
          click_button "Join"

          assert_text "Welcome, #{name}"
          assert_text "Waiting for the host to start"
          connect_turbo_cable_stream_sources
        end
      end
    end

    def host_sees_joined_players
      Capybara.using_session(:host) do
        @player_names.each do |name|
          assert_text name
        end

        assert_text "PLAYERS JOINED\n5"
      end

      assert_equal 5, @game.reload.participants.count
    end

    def host_starts_quiz
      Capybara.using_session(:host) do
        click_button "Start Quiz"

        connect_turbo_cable_stream_sources
        connect_turbo_cable_stream_sources

        assert_current_question_visible_for_host(@quiz.questions.first)
        assert_selector "[data-player-count]", text: "5"
        assert_selector "[data-response-count]", text: "0 / 5"
      end
    end

    def players_see_first_question
      first_question = @quiz.questions.first

      @player_names.each_with_index do |_name, index|
        Capybara.using_session(player_session(index)) do
          assert_current_question_visible_for_player(first_question)
        end
      end
    end

    def play_question_in_two_one_two_blocks(question, first_pair, solo_player, last_pair)
      answer_players(first_pair, question)
      assert_host_response_count(2)
      assert_players_have_submitted(first_pair)
      assert_players_still_answering([ solo_player, *last_pair ], question)

      answer_player(solo_player, question)
      assert_host_response_count(3)
      assert_players_have_submitted([ *first_pair, solo_player ])
      assert_players_still_answering(last_pair, question)

      answer_players(last_pair, question)
      assert_reviewing_state_for_everyone(question)
    end

    def play_question_with_all_players_answering_rapidly(question)
      answer_players((0...@player_names.length).to_a, question)
      assert_reviewing_state_for_everyone(question)
    end

    def advance_host_to_next_question(current_question, next_question)
      Capybara.using_session(:host) do
        assert_text rendered_question_text(current_question)
        assert_button next_button_label_for(current_question)
        click_button next_button_label_for(current_question)

        connect_turbo_cable_stream_sources
        connect_turbo_cable_stream_sources

        assert_current_question_visible_for_host(next_question)
        assert_selector "[data-player-count]", text: "5"
        assert_selector "[data-response-count]", text: "0 / 5"
      end
    end

    def players_see_question(question)
      @player_names.each_with_index do |_name, index|
        Capybara.using_session(player_session(index)) do
          ensure_player_active_question(question)
          assert_current_question_visible_for_player(question)
        end
      end
    end

    def assert_current_question_visible_for_host(question)
      assert_text rendered_question_text(question)
      assert_button "Finish Question"
    end

    def assert_current_question_visible_for_player(question)
      assert_text rendered_question_text(question)
      question.answers.each do |answer|
        assert_button answer.body
      end
    end

    def answer_players(indexes, question)
      indexes.each do |index|
        answer_player(index, question)
      end
    end

    def answer_player(index, question)
      Capybara.using_session(player_session(index)) do
        answer_button_text = question.answers.find_by(correct: true).body

        begin
          assert_current_question_visible_for_player(question)
          click_button answer_button_text
        rescue Playwright::Error => error
          raise unless error.message.include?("Element is not attached to the DOM")

          visit play_path(code: @game.code)
          ensure_player_active_question(question)
          click_button answer_button_text
        end
      end
    end

    def assert_host_response_count(answered_count)
      Capybara.using_session(:host) do
        assert_text @quiz.title
        assert_selector "[data-player-count]", text: "5"
        ensure_host_response_count(answered_count)
      end
    end

    def assert_players_have_submitted(indexes)
      indexes.each do |index|
        Capybara.using_session(player_session(index)) do
          assert_text "Answer submitted!"
          assert_text "Waiting for results…"
          assert_no_selector "[data-leaderboard]"
        end
      end
    end

    def assert_players_still_answering(indexes, question)
      indexes.each do |index|
        Capybara.using_session(player_session(index)) do
          assert_current_question_visible_for_player(question)
          assert_no_text "Answer submitted!"
        end
      end
    end

    def assert_reviewing_state_for_everyone(question)
      Capybara.using_session(:host) do
        assert_text rendered_question_text(question)
        assert_text "CORRECT ANSWER"
        assert_text question.answers.find_by(correct: true).body
        assert_button next_button_label_for(question)
        assert_selector "[data-leaderboard]"
      end

      @player_names.each_with_index do |_name, index|
        Capybara.using_session(player_session(index)) do
          connect_turbo_cable_stream_sources
          ensure_player_reviewing_state
          assert_text rendered_question_text(question)
          assert_text question.answers.find_by(correct: true).body
          assert_selector "[data-leaderboard]"
          assert_no_text "Answer submitted!"
        end
      end
    end

    def ensure_player_reviewing_state
      return if page.has_selector?("[data-game-status='reviewing']", wait: 5)

      visit play_path(code: @game.code)
      assert_selector "[data-game-status='reviewing']"
    end

    def ensure_player_active_question(question)
      return if page.has_selector?("[data-game-status='active']", wait: 5) && page.has_text?(rendered_question_text(question))

      visit play_path(code: @game.code)
      assert_selector "[data-game-status='active']"
      assert_text rendered_question_text(question)
    end

    def finish_quiz_from_last_review_screen(last_question)
      Capybara.using_session(:host) do
        assert_text rendered_question_text(last_question)
        assert_button "Show Results"
        click_button "Show Results"

        assert_text "Game Over"
        assert_selector "[data-player-count]", text: "5"
        assert_selector "[data-leaderboard]"
      end

      @player_names.each_with_index do |name, index|
        Capybara.using_session(player_session(index)) do
          ensure_player_finished_state
          assert_text "Game Over!"
          assert_text "Thanks for playing, #{name}"
          assert_selector "[data-leaderboard]"
        end
      end
    end

    def ensure_player_finished_state
      return if page.has_selector?("[data-game-status='finished']", wait: 5)

      visit play_path(code: @game.code)
      assert_selector "[data-game-status='finished']"
    end

    def ensure_host_response_count(answered_count)
      expected_text = "#{answered_count} / 5"
      return if page.has_selector?("[data-response-count]", text: expected_text, wait: 5)

      visit game_path(@game)
      connect_turbo_cable_stream_sources
      connect_turbo_cable_stream_sources
      assert_selector "[data-response-count]", text: expected_text
    end

    def next_button_label_for(question)
      @quiz.questions.where("position > ?", question.position).exists? ? "Next Question" : "Show Results"
    end

    def rendered_question_text(question)
      CGI.unescapeHTML(ActionView::Base.full_sanitizer.sanitize(QuestionRenderer.new(question.body).html)).squish
    end

    def player_session(index)
      "player_#{index + 1}".to_sym
    end
end
