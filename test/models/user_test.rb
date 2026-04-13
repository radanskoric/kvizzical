require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid with a name" do
    user = User.new(name: "Alice")
    assert user.valid?
  end

  test "invalid without a name" do
    user = User.new(name: nil)
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "generates a session_token on create" do
    user = User.create!(name: "Alice")
    assert_not_nil user.session_token
    assert user.session_token.length >= 20
  end

  test "session_token is unique" do
    user1 = User.create!(name: "Alice")
    user2 = User.create!(name: "Bob")
    assert_not_equal user1.session_token, user2.session_token
  end

  test "has many participants" do
    user = users(:alice)
    assert_respond_to user, :participants
  end

  test "destroying a user preserves participants by nullifying the user link" do
    game = games(:active_game)
    user = User.create!(name: "Private Player")
    participant = Participant.create!(user: user, game: game)

    Response.create!(
      participant: participant,
      question: game.current_question,
      answer: answers(:mvc_correct),
      responded_at: game.question_opened_at + 1.second
    )

    assert_difference "User.count", -1 do
      user.destroy!
    end

    participant.reload
    assert_nil participant.user
    assert_equal "Anonymous", participant.name
    assert_equal 1, participant.responses.count
  end
end
