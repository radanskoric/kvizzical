require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset builds the password reset email" do
    user = users(:alice)

    email = PasswordsMailer.reset(user)

    assert_equal [ user.email_address ], email.to
    assert_equal [ "from@example.com" ], email.from
    assert_equal "Reset your password", email.subject
    assert_match %r{http://example.com/passwords/.+/edit}, email.body.encoded
    assert_includes email.body.encoded, "This link will expire in 15 minutes."
  end
end
