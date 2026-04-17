require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "render_question wraps rendered question HTML in the expected container" do
    question = Question.new(body: "# Hello")

    rendered = render_question(question)

    assert_includes rendered, 'class="prose lg:prose-xl mx-auto wrap-anywhere prose-figure:flex prose-figure:justify-center prose-figure:my-5 text-left"'
    assert_includes rendered, "<h1 id=\"hello\">Hello</h1>"
  end
end
