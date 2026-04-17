class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_player_user, :anonymous_user

  private

    def current_player_user
      current_user || anonymous_user
    end

    def anonymous_user
      return unless session[:user_session_token]

      @anonymous_user ||= User.find_by(session_token: session[:user_session_token])
    end
end
