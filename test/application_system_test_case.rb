require "test_helper"
require "capybara/playwright"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  Capybara.register_driver :playwright_chromium do |app|
    Capybara::Playwright::Driver.new(app,
      browser_type: :chromium,
      headless: true,
      screen_size: [ 1400, 1400 ]
    )
  end

  driven_by :playwright_chromium
end
