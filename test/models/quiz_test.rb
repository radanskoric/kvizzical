require "test_helper"

class QuizTest < ActiveSupport::TestCase
  test "valid with a title" do
    quiz = Quiz.new(title: "Ruby Trivia")
    assert quiz.valid?
  end

  test "invalid without a title" do
    quiz = Quiz.new(title: nil)
    assert_not quiz.valid?
    assert_includes quiz.errors[:title], "can't be blank"
  end
end
