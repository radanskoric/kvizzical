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
      class: "score-badge #{response_score_badge_classes(score)}"
    )
  end

  def render_leaderboard_movement(places_moved)
    content_tag(
      :span,
      format_leaderboard_movement(places_moved),
      data: { leaderboard_movement: true },
      class: "leaderboard-movement #{leaderboard_movement_classes(places_moved)}"
    )
  end

  private

  def response_score_badge_classes(score)
    if score > 500
      "score-badge-high"
    elsif score.positive?
      "score-badge-medium"
    else
      "score-badge-low"
    end
  end

  def format_response_score(score)
    "+#{score.to_i}"
  end

  def leaderboard_movement_classes(places_moved)
    if places_moved.positive?
      "leaderboard-movement-up"
    elsif places_moved.negative?
      "leaderboard-movement-down"
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
