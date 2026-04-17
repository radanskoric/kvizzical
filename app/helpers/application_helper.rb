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
end
