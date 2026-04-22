require "test_helper"

class ParticipantTest < ActiveSupport::TestCase
  test "valid with user and game" do
    participant = Participant.new(
      user: users(:alice),
      game: games(:waiting_game)
    )
    assert participant.valid?
  end

  test "valid without a user" do
    participant = Participant.new(game: games(:waiting_game))
    assert participant.valid?
  end

  test "invalid without a game" do
    participant = Participant.new(user: users(:alice))
    assert_not participant.valid?
  end

  test "enforces uniqueness of user per game" do
    Participant.create!(user: users(:alice), game: games(:waiting_game))
    duplicate = Participant.new(user: users(:alice), game: games(:waiting_game))
    assert_not duplicate.valid?
  end

  test "same user can join different games" do
    game2 = Game.create!(quiz: quizzes(:ruby_trivia))
    p1 = games(:waiting_game).participants.create!(user: users(:alice))
    p2 = Participant.new(user: users(:alice), game: game2)
    assert p2.valid?
  end

  test "allows multiple anonymous participants in the same game" do
    game = games(:waiting_game)
    participant1 = game.participants.create!
    participant2 = Participant.new(game: game)

    assert participant1.persisted?
    assert participant2.valid?
  end

  test "returns user name when user is present" do
    participant = Participant.new(user: users(:alice), game: games(:waiting_game))
    assert_equal "Alice", participant.name
  end

  test "returns anonymous when user is missing" do
    participant = Participant.new(game: games(:waiting_game))
    assert_equal "Anonymous", participant.name
  end

  test "has many responses" do
    participant = participants(:alice_in_game)
    assert_respond_to participant, :responses
  end
end
