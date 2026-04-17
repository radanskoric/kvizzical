require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test "anonymous_user returns nil when session token is not set" do
    get root_path

    assert_response :success
    assert_nil session[:user_session_token]
  end
end
