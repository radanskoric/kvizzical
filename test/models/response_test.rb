require "test_helper"

class ResponseTest < ActiveSupport::TestCase
  test "valid with participant, question, answer, and responded_at" do
    response = Response.new(
      participant: participants(:alice_in_game),
      question: questions(:mvc_question),
      answer: answers(:mvc_correct),
      responded_at: Time.current
    )
    assert response.valid?
  end

  test "invalid without a participant" do
    response = Response.new(
      question: questions(:mvc_question),
      answer: answers(:mvc_correct),
      responded_at: Time.current
    )
    assert_not response.valid?
  end

  test "invalid without a question" do
    response = Response.new(
      participant: participants(:alice_in_game),
      answer: answers(:mvc_correct),
      responded_at: Time.current
    )
    assert_not response.valid?
  end

  test "invalid without an answer" do
    response = Response.new(
      participant: participants(:alice_in_game),
      question: questions(:mvc_question),
      responded_at: Time.current
    )
    assert_not response.valid?
  end

  test "enforces one response per participant per question" do
    Response.create!(
      participant: participants(:alice_in_game),
      question: questions(:mvc_question),
      answer: answers(:mvc_correct),
      responded_at: Time.current
    )

    duplicate = Response.new(
      participant: participants(:alice_in_game),
      question: questions(:mvc_question),
      answer: answers(:mvc_wrong_1),
      responded_at: Time.current
    )
    assert_not duplicate.valid?
  end

  test "different participants can answer the same question" do
    Response.create!(
      participant: participants(:alice_in_game),
      question: questions(:mvc_question),
      answer: answers(:mvc_correct),
      responded_at: Time.current
    )

    other = Response.new(
      participant: participants(:bob_in_game),
      question: questions(:mvc_question),
      answer: answers(:mvc_wrong_1),
      responded_at: Time.current
    )
    assert other.valid?
  end

  test "calculates max score for instant correct answer" do
    game = games(:active_game)
    response = Response.create!(
      participant: participants(:alice_in_game),
      question: questions(:mvc_question),
      answer: answers(:mvc_correct),
      responded_at: game.question_opened_at
    )
    assert_equal 1000, response.score
  end

  test "calculates reduced score for slower correct answer" do
    game = games(:active_game)
    question = questions(:mvc_question)
    halfway = game.question_opened_at + (question.time_limit_seconds / 2.0).seconds

    response = Response.create!(
      participant: participants(:alice_in_game),
      question: question,
      answer: answers(:mvc_correct),
      responded_at: halfway
    )

    assert_in_delta 550, response.score, 50
  end

  test "scores zero for wrong answer" do
    game = games(:active_game)
    response = Response.create!(
      participant: participants(:alice_in_game),
      question: questions(:mvc_question),
      answer: answers(:mvc_wrong_1),
      responded_at: game.question_opened_at
    )
    assert_equal 0, response.score
  end

  test "scores minimum points for last-second correct answer" do
    game = games(:active_game)
    question = questions(:mvc_question)
    just_before_deadline = game.question_opened_at + question.time_limit_seconds.seconds - 0.1.seconds

    response = Response.create!(
      participant: participants(:alice_in_game),
      question: question,
      answer: answers(:mvc_correct),
      responded_at: just_before_deadline
    )

    assert response.score >= 100
    assert response.score <= 150
  end

  test "scores zero when answer is nil" do
    game = games(:active_game)
    response = Response.new(
      participant: participants(:alice_in_game),
      question: questions(:mvc_question),
      answer: nil,
      responded_at: game.question_opened_at
    )

    response.send(:calculate_score)

    assert_equal 0, response.score
  end

  test "scores zero when participant is nil" do
    game = games(:active_game)
    response = Response.new(
      participant: nil,
      question: questions(:mvc_question),
      answer: answers(:mvc_correct),
      responded_at: game.question_opened_at
    )

    response.send(:calculate_score)

    assert_equal 0, response.score
  end

  test "scores zero when question is nil" do
    game = games(:active_game)
    response = Response.new(
      participant: participants(:alice_in_game),
      question: nil,
      answer: answers(:mvc_correct),
      responded_at: game.question_opened_at
    )

    response.send(:calculate_score)

    assert_equal 0, response.score
  end
end
