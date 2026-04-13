require "test_helper"

class QrCodeHelperTest < ActionView::TestCase
  test "qr_code_svg returns an SVG string" do
    svg = qr_code_svg("https://example.com")
    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end

  test "qr_code_svg respects size parameter" do
    svg = qr_code_svg("https://example.com", size: 300)
    assert_includes svg, 'width="300"'
    assert_includes svg, 'height="300"'
  end
end
