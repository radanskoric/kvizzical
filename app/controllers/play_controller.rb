class PlayController < ApplicationController
  before_action :set_game

  def show
    @user = current_user
    if @user
      @participant = @game.participants.find_or_create_by!(user: @user)
    end
  end

  def create
    user = User.find_or_initialize_by(session_token: session[:user_session_token])
    user.name = params[:name]

    if user.new_record?
      user.save!
      session[:user_session_token] = user.session_token
    else
      user.save!
    end

    participant = @game.participants.find_or_create_by!(user: user)
    @game.broadcast_player_list if participant.previously_new_record?
    redirect_to play_path(code: @game.code)
  end

  private

  def set_game
    @game = Game.find_by!(code: params[:code])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def current_user
    return unless session[:user_session_token]

    User.find_by(session_token: session[:user_session_token])
  end
end
