module TurboStreamActionsHelper
  def versioned_replace(target, content = nil, **rendering, &block)
    template = render_template(target, content, allow_inferred_rendering: true, **rendering, &block)

    turbo_stream_action_tag :versioned_replace, target: target, method: :morph, template: template
  end
end

Turbo::Streams::TagBuilder.include(TurboStreamActionsHelper)
