require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  test "valid with body and question" do
    answer = Answer.new(
      question: questions(:mvc_question),
      body: "Model-View-Controller"
    )
    assert answer.valid?
  end

  test "invalid without a body" do
    answer = Answer.new(question: questions(:mvc_question))
    assert_not answer.valid?
    assert_includes answer.errors[:body], "can't be blank"
  end

  test "invalid without a question" do
    answer = Answer.new(body: "Some answer")
    assert_not answer.valid?
  end

  test "defaults correct to false" do
    answer = Answer.new
    assert_equal false, answer.correct
  end

  test "allows one correct answer per question" do
    answer = Answer.new(
      question: questions(:mvc_question),
      body: "Another correct answer",
      correct: true
    )
    assert_not answer.valid?
    assert_includes answer.errors[:correct], "has already been taken"
  end

  test "allows multiple incorrect answers per question" do
    question = questions(:mvc_question)
    answer = Answer.new(question: question, body: "Wrong answer", correct: false)
    assert answer.valid?
  end
end
