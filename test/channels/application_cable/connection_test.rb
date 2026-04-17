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

    test "rejects connection without a signed session cookie" do
      assert_raises(ActionCable::Connection::Authorization::UnauthorizedError) { connect }
    end
  end
end
