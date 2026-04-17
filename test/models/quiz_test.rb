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

  test "keeps an explicitly provided preview token" do
    quiz = Quiz.create!(title: "Custom Token Quiz", creator: users(:alice), secret_preview_token: "custom-preview-token")

    assert_equal "custom-preview-token", quiz.secret_preview_token
  end

  test "retries preview token generation when a collision occurs" do
    existing_quiz = quizzes(:ruby_trivia)
    generated_tokens = [ existing_quiz.secret_preview_token, "fresh-preview-token" ]
    original_method = SecureRandom.method(:urlsafe_base64)

    SecureRandom.define_singleton_method(:urlsafe_base64) { |_length| generated_tokens.shift }

    begin
      quiz = Quiz.create!(title: "Collision Quiz", creator: users(:alice))

      assert_equal "fresh-preview-token", quiz.secret_preview_token
    ensure
      SecureRandom.define_singleton_method(:urlsafe_base64, original_method)
    end
  end
end
