module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private
      def set_current_user
        self.current_user = authenticated_user || anonymous_player_user
      end

      def authenticated_user
        return unless cookies.signed[:session_id]

        Session.find_by(id: cookies.signed[:session_id])&.user
      end

      def anonymous_player_user
        return unless request.session[:user_session_token]

        User.find_by(session_token: request.session[:user_session_token])
      end
  end
end
