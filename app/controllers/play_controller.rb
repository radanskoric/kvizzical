class PlayController < ApplicationController
  allow_unauthenticated_access
  before_action :set_game

  def show
    @user = current_player_user
    if @user
      @participant = @game.participants.find_or_initialize_by(user: @user)
      if @participant.new_record?
        @participant.save!
        @game.reload.broadcast_game_state
      end
    end
  end

  def create
    user = current_user || User.find_or_initialize_by(session_token: session[:user_session_token])
    user.name = params[:name]
    user.save!

    session[:user_session_token] = user.session_token unless current_user

    @game.participants.find_or_create_by!(user: user)
    @game.reload.broadcast_game_state
    redirect_to play_path(code: @game.code)
  end

  private

  def set_game
    @game = Game.find_by!(code: params[:code])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end
