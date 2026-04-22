require "test_helper"

class TurboStreamActionsHelperTest < ActionView::TestCase
  def turbo_stream_tag_builder
    Turbo::Streams::TagBuilder.new(view)
  end

  test "versioned_replace renders a versioned turbo stream action" do
    rendered = turbo_stream_tag_builder.versioned_replace("player_game_area", "<div data-version=\"2\">Updated</div>")

    assert_includes rendered, 'action="versioned_replace"'
    assert_includes rendered, 'method="morph"'
    assert_includes rendered, 'target="player_game_area"'
    assert_includes rendered, '<template><div data-version="2">Updated</div></template>'
  end

  test "turbo stream builder includes versioned_replace helper" do
    assert_respond_to turbo_stream_tag_builder, :versioned_replace
  end
end
