module QrCodeHelper
  def qr_code_svg(url, size: 200)
    qr = RQRCode::QRCode.new(url)
    svg = qr.as_svg(
      shape_rendering: "crispEdges",
      module_size: 4,
      standalone: true,
      use_path: true,
      viewbox: true,
      svg_attributes: {
        width: size,
        height: size,
        class: "inline-block"
      }
    )
    svg.html_safe
  end
end
