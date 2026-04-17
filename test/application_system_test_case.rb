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

  private

    def sign_in_as(user, password: "password")
      visit new_session_path
      fill_in "email_address", with: user.email_address
      fill_in "password", with: password
      click_button "Log in"
      assert_text "Sign out"
    end
end
