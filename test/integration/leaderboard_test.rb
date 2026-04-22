require "test_helper"

class LeaderboardTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:alice))
  end

  test "host dashboard shows leaderboard when game is reviewing" do
    game = games(:active_game)
    alice = participants(:alice_in_game)
    bob = participants(:bob_in_game)

    Response.create!(
      participant: alice,
      question: game.current_question,
      answer: answers(:mvc_correct),
      responded_at: game.question_opened_at + 1.second
    )

    Response.create!(
      participant: bob,
      question: game.current_question,
      answer: answers(:mvc_wrong_1),
      responded_at: game.question_opened_at + 2.seconds
    )

    game.reload
    game.update!(status: :reviewing, question_opened_at: nil)

    get game_path(game)
    assert_response :success
    assert_select "[data-leaderboard]"
    assert_select "[data-leaderboard-entry]", count: 2
  end

  test "host review leaderboard shows reviewed-question scores with threshold colors" do
    game = games(:active_game)
    alice = participants(:alice_in_game)
    bob = participants(:bob_in_game)

    Response.create!(
      participant: alice,
      question: game.current_question,
      answer: answers(:mvc_correct),
      responded_at: game.question_opened_at + 1.second
    )

    Response.create!(
      participant: bob,
      question: game.current_question,
      answer: answers(:mvc_wrong_1),
      responded_at: game.question_opened_at + 2.seconds
    )

    game.reload
    game.update!(status: :reviewing, question_opened_at: nil)

    get game_path(game)

    assert_select "[data-response-score].score-badge.score-badge-high", text: "+960"
    assert_select "[data-response-score].score-badge.score-badge-low", text: "+0"
  end

  test "host review leaderboard shows place movement after reviewed-question scores" do
    game = games(:active_game)
    question = game.current_question
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
      question: question,
      answer: answers(:mvc_wrong_1),
      responded_at: game.question_opened_at + 8.seconds
    )

    Response.create!(
      participant: bob,
      question: question,
      answer: answers(:mvc_correct),
      responded_at: game.question_opened_at + 1.second
    )

    Response.create!(
      participant: charlie,
      question: question,
      answer: answers(:mvc_wrong_1),
      responded_at: game.question_opened_at + 8.seconds
    )

    game.reload
    game.update!(status: :reviewing, question_opened_at: nil)

    get game_path(game)

    assert_select "[data-leaderboard-movement].leaderboard-movement.leaderboard-movement-up", text: "▲2"
    assert_select "[data-leaderboard-movement].leaderboard-movement.leaderboard-movement-down", text: "▼-1", count: 2
  end

  test "leaderboard shows anonymous when participant has no user" do
    game = games(:active_game)
    anonymous_participant = game.participants.create!

    Response.create!(
      participant: anonymous_participant,
      question: game.current_question,
      answer: answers(:mvc_correct),
      responded_at: game.question_opened_at + 1.second
    )

    game.reload
    game.update!(status: :reviewing, question_opened_at: nil)

    get game_path(game)
    assert_response :success
    assert_select "[data-leaderboard]", text: /Anonymous/
  end

  test "host dashboard shows leaderboard when game is finished" do
    game = games(:active_game)
    game.update!(status: :finished, current_question: nil)

    get game_path(game)
    assert_response :success
    assert_select "[data-leaderboard]"
  end

  test "player sees leaderboard when game is finished" do
    game = games(:active_game)

    post play_path(code: game.code), params: { name: "LeaderPlayer" }
    follow_redirect!

    game.reload
    game.update!(status: :finished, current_question: nil)

    get play_path(code: game.code)
    assert_response :success
    assert_select "[data-leaderboard]"
  end

  test "player review leaderboard matches reviewed-question score styling" do
    game = games(:active_game)
    question = game.current_question

    sign_out

    post play_path(code: game.code), params: { name: "LeaderPlayer" }
    player = game.participants.find_by!(user: User.find_by!(session_token: session[:user_session_token]))
    player.reload

    Response.create!(
      participant: participants(:alice_in_game),
      question: question,
      answer: answers(:mvc_correct),
      responded_at: game.question_opened_at + 1.second
    )

    Response.create!(
      participant: player,
      question: question,
      answer: answers(:mvc_correct),
      responded_at: game.question_opened_at + 9.seconds
    )

    game.reload
    game.update!(status: :reviewing, question_opened_at: nil)

    get play_path(code: game.code)

    assert_select "[data-response-score].score-badge.score-badge-high", text: "+960"
    assert_select "[data-response-score].score-badge.score-badge-high", text: "+640"
  end

  test "host review leaderboard shows unchanged place indicator when ranking stays the same" do
    game = games(:active_game)
    question = game.current_question
    previous_question = questions(:gem_question)
    alice = participants(:alice_in_game)
    bob = participants(:bob_in_game)

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

    alice.reload
    bob.reload

    Response.create!(
      participant: alice,
      question: question,
      answer: answers(:mvc_wrong_1),
      responded_at: game.question_opened_at + 1.second
    )

    Response.create!(
      participant: bob,
      question: question,
      answer: answers(:mvc_wrong_1),
      responded_at: game.question_opened_at + 2.seconds
    )

    game.reload
    game.update!(status: :reviewing, question_opened_at: nil)

    get game_path(game)

    assert_select "[data-leaderboard-movement].leaderboard-movement.text-black", text: "-", count: 2
  end
end
