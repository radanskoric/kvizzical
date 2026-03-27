if defined?(LogBench)
  LogBench.setup do |config|
    config.enabled = Rails.env.development?

    # Disable automatic lograge configuration (if you want to configure lograge manually)
    # config.configure_lograge_automatically = false  # (default: true)

    # Customize initialization message
    config.show_init_message = :none

    # Specify which controllers to inject request_id tracking
    # config.base_controller_classes = %w[CustomBaseController] # (default: %w[ApplicationController ActionController::Base])
  end
end
