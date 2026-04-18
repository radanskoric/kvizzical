require "question_renderer"

module ApplicationHelper
  def render_question(question)
    content_tag(
      :div,
      class: "prose lg:prose-xl mx-auto wrap-anywhere prose-figure:flex prose-figure:justify-center prose-figure:my-5 text-left"
    ) do
      QuestionRenderer.new(question.body).html.html_safe
    end
  end

  def render_response_score(response)
    score = response&.score.to_i

    content_tag(
      :span,
      format_response_score(score),
      data: { response_score: true },
      class: "rounded-full px-3 py-1 text-sm font-semibold #{response_score_badge_classes(score)}"
    )
  end

  def render_leaderboard_movement(places_moved)
    content_tag(
      :span,
      format_leaderboard_movement(places_moved),
      data: { leaderboard_movement: true },
      class: "text-sm font-semibold #{leaderboard_movement_classes(places_moved)}"
    )
  end

  private

  def response_score_badge_classes(score)
    if score > 500
      "bg-green-100 text-green-700"
    elsif score.positive?
      "bg-orange-100 text-orange-700"
    else
      "bg-red-100 text-red-700"
    end
  end

  def format_response_score(score)
    "+#{score.to_i}"
  end

  def leaderboard_movement_classes(places_moved)
    if places_moved.positive?
      "text-green-700"
    elsif places_moved.negative?
      "text-red-700"
    else
      "text-black"
    end
  end

  def format_leaderboard_movement(places_moved)
    if places_moved.positive?
      "▲#{places_moved}"
    elsif places_moved.negative?
      "▼#{places_moved}"
    else
      "-"
    end
  end
end
