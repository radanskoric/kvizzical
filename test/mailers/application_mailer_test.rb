require "test_helper"

class ApplicationMailerTest < ActiveSupport::TestCase
  test "inherits from ActionMailer base with default sender and layout" do
    mailer_class = Class.new(ApplicationMailer)

    assert_equal ActionMailer::Base, ApplicationMailer.superclass
    assert_equal "from@example.com", mailer_class.default_params[:from]
    assert_equal "mailer", mailer_class._layout
  end
end
