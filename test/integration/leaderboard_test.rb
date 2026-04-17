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

    game.update!(status: :reviewing, question_opened_at: nil)

    get game_path(game)
    assert_response :success
    assert_select "[data-leaderboard]"
    assert_select "[data-leaderboard-entry]", count: 2
  end

  test "leaderboard shows anonymous when participant has no user" do
    game = games(:active_game)
    anonymous_participant = Participant.create!(game: game)

    Response.create!(
      participant: anonymous_participant,
      question: game.current_question,
      answer: answers(:mvc_correct),
      responded_at: game.question_opened_at + 1.second
    )

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

    game.update!(status: :finished, current_question: nil)

    get play_path(code: game.code)
    assert_response :success
    assert_select "[data-leaderboard]"
  end
end
