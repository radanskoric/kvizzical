require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  test "valid with body, position, and quiz" do
    question = Question.new(
      quiz: quizzes(:ruby_trivia),
      body: "What does MVC stand for?",
      position: 1
    )
    assert question.valid?
  end

  test "invalid without a body" do
    question = Question.new(quiz: quizzes(:ruby_trivia), position: 1)
    assert_not question.valid?
    assert_includes question.errors[:body], "can't be blank"
  end

  test "invalid without a position" do
    question = Question.new(quiz: quizzes(:ruby_trivia), body: "Test?")
    assert_not question.valid?
    assert_includes question.errors[:position], "can't be blank"
  end

  test "invalid without a quiz" do
    question = Question.new(body: "Test?", position: 1)
    assert_not question.valid?
  end

  test "defaults time_limit_seconds to 15" do
    question = Question.new
    assert_equal 15, question.time_limit_seconds
  end

  test "has many answers" do
    question = questions(:mvc_question)
    assert_respond_to question, :answers
  end

  test "has many references" do
    question = questions(:mvc_question)
    assert_respond_to question, :references
  end

  test "destroys associated references when destroyed" do
    question = quizzes(:ruby_trivia).questions.create!(
      body: "Fresh question?",
      position: 99,
      time_limit_seconds: 15
    )
    reference = question.references.create!(url: "https://ruby-doc.org")

    assert_difference "Reference.count", -1 do
      question.destroy
    end

    assert_not Reference.exists?(reference.id)
  end

  test "orders by position" do
    quiz = quizzes(:ruby_trivia)
    positions = quiz.questions.pluck(:position)
    assert_equal positions.sort, positions
  end
end
