require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new renders successfully" do
    get new_registration_path

    assert_response :success
    assert_select "input[name='user[name]']"
  end

  test "create registers a new user and starts an authenticated session" do
    assert_difference [ "User.count", "Session.count" ], 1 do
      post registration_path, params: {
        user: {
          name: "Registered Player",
          email_address: "registered@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
    assert_equal "registered@example.com", User.order(:id).last.email_address
  end

  test "create requires a name" do
    assert_no_difference "User.count" do
      post registration_path, params: {
        user: {
          name: "",
          email_address: "registered@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "div", /Name can't be blank/
  end

  test "new prefills name from anonymous session" do
    post play_path(code: games(:waiting_game).code), params: { name: "Guest Name" }

    get new_registration_path

    assert_response :success
    assert_select "input[name='user[name]'][value='Guest Name']"
  end

  test "create upgrades anonymous user into a registered account" do
    post play_path(code: games(:waiting_game).code), params: { name: "Guest Name" }
    anonymous_user = User.find_by(session_token: session[:user_session_token])

    assert_no_difference "User.count" do
      post registration_path, params: {
        user: {
          name: "Guest Name",
          email_address: "guest@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_redirected_to root_path
    assert_nil session[:user_session_token]
    assert_equal anonymous_user.id, Session.order(:id).last.user_id
    assert_equal "guest@example.com", anonymous_user.reload.email_address
  end

  test "new and create build a fresh user when anonymous session user is already registered" do
    post play_path(code: games(:waiting_game).code), params: { name: "Guest Name" }
    anonymous_user = User.find_by(session_token: session[:user_session_token])
    anonymous_user.update!(email_address: "guest@example.com", password: "password", password_confirmation: "password")

    get new_registration_path, params: { email_address: "prefilled@example.com" }

    assert_response :success
    assert_select "input[name='user[name]'][value='Guest Name']"
    assert_select "input[name='user[email_address]'][value='prefilled@example.com']"

    assert_difference [ "User.count", "Session.count" ], 1 do
      post registration_path, params: {
        user: {
          name: "Fresh User",
          email_address: "fresh@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_redirected_to root_path
    assert_equal anonymous_user.id, anonymous_user.reload.id
    assert_equal "guest@example.com", anonymous_user.email_address
    assert_equal "fresh@example.com", User.order(:id).last.email_address
  end
end
