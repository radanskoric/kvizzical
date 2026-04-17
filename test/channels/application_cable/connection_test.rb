require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    test "connects with a signed session cookie" do
      user = users(:alice)
      session = Session.create!(user: user, user_agent: "Rails Test", ip_address: "127.0.0.1")
      cookies.signed[:session_id] = session.id

      connect

      assert_equal user, connection.current_user
    end

    test "connects with an anonymous player session token" do
      user = users(:alice)

      connect session: { user_session_token: user.session_token }

      assert_equal user, connection.current_user
    end

    test "rejects connection with an invalid signed session cookie" do
      cookies.signed[:session_id] = -1

      assert_raises(ActionCable::Connection::Authorization::UnauthorizedError) { connect }
    end

    test "rejects connection with an invalid anonymous player session token" do
      assert_raises(ActionCable::Connection::Authorization::UnauthorizedError) do
        connect session: { user_session_token: "missing-token" }
      end
    end

    test "rejects connection without a signed session cookie" do
      assert_raises(ActionCable::Connection::Authorization::UnauthorizedError) { connect }
    end
  end
end
