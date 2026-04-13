require "test_helper"

class GameTest < ActiveSupport::TestCase
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
end
