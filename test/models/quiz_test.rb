require "test_helper"

class QuizTest < ActiveSupport::TestCase
  test "valid with a title" do
    quiz = Quiz.new(title: "Ruby Trivia", creator: users(:alice))
    assert quiz.valid?
  end

  test "invalid without a title" do
    quiz = Quiz.new(title: nil, creator: users(:alice))
    assert_not quiz.valid?
    assert_includes quiz.errors[:title], "can't be blank"
  end

  test "belongs to a creator when assigned" do
    quiz = quizzes(:ruby_trivia)

    assert_equal users(:alice), quiz.creator
  end
end
