require "test_helper"
require "action_cable/test_helper"

class GameTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "valid with a quiz" do
    game = Game.new(quiz: quizzes(:ruby_trivia))
    assert game.valid?
  end

  test "invalid without a quiz" do
    game = Game.new
    assert_not game.valid?
  end

  test "generates a unique code on create" do
    game = Game.create!(quiz: quizzes(:ruby_trivia))
    assert_not_nil game.code
    assert_match(/\A[A-Z0-9]{6}\z/, game.code)
  end

  test "code is unique" do
    game1 = Game.create!(quiz: quizzes(:ruby_trivia))
    game2 = Game.create!(quiz: quizzes(:ruby_trivia))
    assert_not_equal game1.code, game2.code
  end

  test "defaults to waiting status" do
    game = Game.create!(quiz: quizzes(:ruby_trivia))
    assert game.waiting?
  end

  test "defaults lock_version to zero" do
    game = Game.create!(quiz: quizzes(:ruby_trivia))

    assert_equal 0, game.lock_version
  end

  test "has waiting, active, and finished statuses" do
    game = games(:waiting_game)
    assert game.waiting?

    game.status = :active
    assert game.active?

    game.status = :finished
    assert game.finished?
  end

  test "has many participants" do
    game = games(:waiting_game)
    assert_respond_to game, :participants
  end

  test "belongs to current_question optionally" do
    game = games(:waiting_game)
    assert_nil game.current_question

    game.current_question = questions(:mvc_question)
    assert_equal questions(:mvc_question), game.current_question
  end

  test "all_answered is false when there are no participants" do
    game = Game.create!(quiz: quizzes(:ruby_trivia))
    game.start!

    assert_not game.all_answered?
  end

  test "all_answered is true when every participant answered the current question" do
    game = games(:active_game)

    Response.create!(
      participant: participants(:alice_in_game),
      question: game.current_question,
      answer: answers(:mvc_correct),
      responded_at: game.question_opened_at + 1.second
    )

    Response.create!(
      participant: participants(:bob_in_game),
      question: game.current_question,
      answer: answers(:mvc_wrong_1),
      responded_at: game.question_opened_at + 2.seconds
    )

    assert game.all_answered?
  end

  test "all_answered is false when only some participants answered the current question" do
    game = games(:active_game)

    Response.create!(
      participant: participants(:alice_in_game),
      question: game.current_question,
      answer: answers(:mvc_correct),
      responded_at: game.question_opened_at + 1.second
    )

    assert_not game.all_answered?
  end

  test "all_answered is false when game is active without a current question" do
    game = games(:active_game)
    game.update!(current_question: nil)

    assert_not game.all_answered?
  end

  test "with_stale_retry reloads and retries on stale object error" do
    game = games(:waiting_game)
    calls = []

    game.with_stale_retry(attempts: 2) do |current_game|
      calls << current_game.lock_version

      if calls.one?
        game.update!(status: :active, current_question: questions(:mvc_question), question_opened_at: Time.current)
        raise ActiveRecord::StaleObjectError.new(current_game, "update")
      end
    end

    assert_equal [ 0, 1 ], calls
  end

  test "with_stale_retry raises when retry budget is exhausted" do
    game = games(:waiting_game)

    assert_raises(ActiveRecord::StaleObjectError) do
      game.with_stale_retry(attempts: 1) do |current_game|
        raise ActiveRecord::StaleObjectError.new(current_game, "update")
      end
    end
  end

  test "participant touch increments game lock_version" do
    game = games(:waiting_game)

    assert_changes -> { game.reload.lock_version }, from: 0, to: 1 do
      game.participants.create!(user: users(:alice))
    end
  end

  test "response touch increments game lock_version through participant" do
    game = games(:active_game)
    participant = participants(:alice_in_game)

    assert_changes -> { game.reload.lock_version }, from: 0, to: 1 do
      Response.create!(
        participant: participant,
        question: game.current_question,
        answer: answers(:mvc_correct),
        responded_at: game.question_opened_at + 1.second
      )
    end
  end

  test "previous_leaderboard_positions returns empty hash when game is not reviewing" do
    game = games(:active_game)

    assert_equal({}, game.previous_leaderboard_positions)
  end

  test "previous_leaderboard_positions ranks players by score before the reviewed question" do
    game = games(:active_game)
    reviewed_question = game.current_question
    previous_question = questions(:gem_question)
    alice = participants(:alice_in_game)
    bob = participants(:bob_in_game)
    charlie = game.participants.create!(user: User.create!(name: "Charlie", session_token: SecureRandom.hex(16)))

    Response.create!(
      participant: alice,
      question: previous_question,
      answer: answers(:gem_correct),
      responded_at: game.question_opened_at + 14.seconds
    )

    Response.create!(
      participant: bob,
      question: previous_question,
      answer: answers(:gem_wrong_1),
      responded_at: game.question_opened_at + 14.seconds
    )

    charlie.reload
    Response.create!(
      participant: charlie,
      question: previous_question,
      answer: answers(:gem_correct),
      responded_at: game.question_opened_at + 14.5.seconds
    )

    alice.reload
    bob.reload
    charlie.reload

    Response.create!(
      participant: alice,
      question: reviewed_question,
      answer: answers(:mvc_wrong_1),
      responded_at: game.question_opened_at + 8.seconds
    )

    Response.create!(
      participant: bob,
      question: reviewed_question,
      answer: answers(:mvc_correct),
      responded_at: game.question_opened_at + 1.second
    )

    Response.create!(
      participant: charlie,
      question: reviewed_question,
      answer: answers(:mvc_wrong_1),
      responded_at: game.question_opened_at + 8.seconds
    )

    game.reload
    game.update!(status: :reviewing, question_opened_at: nil)

    assert_equal(
      {
        alice.id => 0,
        charlie.id => 1,
        bob.id => 2
      },
      game.previous_leaderboard_positions
    )
  end

  test "broadcast_game_state broadcasts to a signed in participant stream" do
    game = games(:active_game)
    participant = participants(:alice_in_game)

    player_broadcasts = capture_broadcasts("game_#{game.id}_player_#{participant.user_id}") do
      game.broadcast_game_state
    end

    assert_equal 1, player_broadcasts.size
    assert_includes player_broadcasts.first, 'target="player_game_area"'
    assert_includes player_broadcasts.first, 'action="versioned_replace"'
    assert_includes player_broadcasts.first, %(data-version="#{game.lock_version}")
  end

  test "broadcast_game_state does not broadcast to an anonymous participant stream" do
    game = games(:active_game)
    game.participants.create!

    player_broadcasts = capture_broadcasts("game_#{game.id}_player_") do
      game.broadcast_game_state
    end

    assert_empty player_broadcasts
  end

  test "broadcast_game_state targets the host area on the host stream" do
    game = games(:waiting_game)
    stream_name = game.to_gid_param

    host_broadcasts = capture_broadcasts(stream_name) do
      game.broadcast_game_state
    end

    assert_equal 1, host_broadcasts.size
    assert_includes host_broadcasts.first, 'target="game_host_area"'
    assert_includes host_broadcasts.first, 'action="versioned_replace"'
    assert_includes host_broadcasts.first, %(data-version="#{game.lock_version}")
  end

  test "generate_code retries when a generated code already exists" do
    existing = Game.create!(quiz: quizzes(:ruby_trivia), code: "TAKEN1")
    generated_codes = [ existing.code, "FRESH2" ]

    SecureRandom.singleton_class.class_eval do
      alias_method :original_alphanumeric_for_test, :alphanumeric
      define_method(:alphanumeric) { |_length| generated_codes.shift }
    end

    game = Game.create!(quiz: quizzes(:ruby_trivia))
    assert_equal "FRESH2", game.code
  ensure
    SecureRandom.singleton_class.class_eval do
      alias_method :alphanumeric, :original_alphanumeric_for_test
      remove_method :original_alphanumeric_for_test
    end
  end

  test "start! does nothing when game is not waiting" do
    game = games(:active_game)
    current_question = game.current_question

    game.start!

    game.reload
    assert game.active?
    assert_equal current_question, game.current_question
  end

  test "finish_question! does nothing when game is not active" do
    game = games(:waiting_game)

    game.finish_question!

    game.reload
    assert game.waiting?
    assert_nil game.current_question
  end

  test "advance! does nothing when game is not reviewing" do
    game = games(:waiting_game)

    game.advance!

    game.reload
    assert game.waiting?
    assert_nil game.current_question
  end

  test "all_answered? returns false when game is not active" do
    game = games(:waiting_game)

    assert_not game.all_answered?
  end
end
