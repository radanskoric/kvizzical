require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "render_question wraps rendered question HTML in the expected container" do
    question = Question.new(body: "# Hello")

    rendered = render_question(question)

    assert_includes rendered, 'class="prose lg:prose-xl mx-auto wrap-anywhere prose-figure:flex prose-figure:justify-center prose-figure:my-5 text-left"'
    assert_includes rendered, "<h1 id=\"hello\">Hello</h1>"
  end

  test "render_response_score renders a green badge for high scores" do
    rendered = render_response_score(Response.new(score: 501))

    assert_includes rendered, 'data-response-score="true"'
    assert_includes rendered, 'class="rounded-full px-3 py-1 text-sm font-semibold bg-green-100 text-green-700"'
    assert_includes rendered, ">+501<"
  end

  test "render_response_score renders an orange badge for positive scores up to 500" do
    rendered = render_response_score(Response.new(score: 500))

    assert_includes rendered, 'class="rounded-full px-3 py-1 text-sm font-semibold bg-orange-100 text-orange-700"'
    assert_includes rendered, ">+500<"
  end

  test "render_response_score renders a red badge for a missing response" do
    rendered = render_response_score(nil)

    assert_includes rendered, 'class="rounded-full px-3 py-1 text-sm font-semibold bg-red-100 text-red-700"'
    assert_includes rendered, ">+0<"
  end

  test "render_leaderboard_movement renders green upward movement" do
    rendered = render_leaderboard_movement(2)

    assert_includes rendered, 'data-leaderboard-movement="true"'
    assert_includes rendered, 'class="text-sm font-semibold text-green-700"'
    assert_includes rendered, ">▲2<"
  end

  test "render_leaderboard_movement renders black unchanged indicator" do
    rendered = render_leaderboard_movement(0)

    assert_includes rendered, 'class="text-sm font-semibold text-black"'
    assert_includes rendered, ">-<"
  end

  test "render_leaderboard_movement renders red downward movement" do
    rendered = render_leaderboard_movement(-2)

    assert_includes rendered, 'class="text-sm font-semibold text-red-700"'
    assert_includes rendered, ">▼-2<"
  end

  test "format_response_score returns a whole-number score with leading plus sign" do
    assert_equal "+460", format_response_score(460.9)
  end
end
