require "test_helper"

class ApplicationJobTest < ActiveSupport::TestCase
  test "inherits from ActiveJob base" do
    assert_equal ActiveJob::Base, ApplicationJob.superclass
  end
end
