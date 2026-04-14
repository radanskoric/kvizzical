SimpleCov.start "rails" do
  enable_coverage :branch
  merge_timeout 3600
  command_name "Rails Tests"
end

SimpleCov.enable_for_subprocesses true

SimpleCov.at_fork do |pid|
  SimpleCov.command_name "#{SimpleCov.command_name} (subprocess: #{pid})"
  SimpleCov.print_error_status = false
  SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter
  SimpleCov.minimum_coverage 0
  SimpleCov.start
end
