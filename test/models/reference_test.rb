require "test_helper"

class ReferenceTest < ActiveSupport::TestCase
  test "valid with url and question" do
    reference = Reference.new(
      question: questions(:mvc_question),
      url: "https://guides.rubyonrails.org/getting_started.html"
    )

    assert reference.valid?
  end

  test "invalid without a url" do
    reference = Reference.new(question: questions(:mvc_question))

    assert_not reference.valid?
    assert_includes reference.errors[:url], "can't be blank"
  end

  test "invalid without a question" do
    reference = Reference.new(url: "https://www.ruby-lang.org")

    assert_not reference.valid?
  end
end
