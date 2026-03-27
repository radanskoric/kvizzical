# Use this hook to configure the litestream-ruby gem.
# All configuration options will be available as environment variables, e.g.
# config.replica_bucket becomes LITESTREAM_REPLICA_BUCKET
# This allows you to configure Litestream using Rails encrypted credentials,
# or some other mechanism where the values are only available at runtime.

Rails.application.configure do
  # Configure the default Litestream config path
  config.litestream.config_path = Rails.root.join("config", "litestream_#{Rails.env}.yml")

  # Configure the Litestream dashboard
  #
  # Set the default base controller class
  # config.litestream.base_controller_class = "MyApplicationController"
  #
  # Set authentication credentials for Litestream dashboard
  # config.litestream.username = litestream_credentials&.username
  # config.litestream.password = litestream_credentials&.password
end
