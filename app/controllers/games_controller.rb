class GamesController < ApplicationController
  before_action :set_game, except: [ :create ]

  def show
  end

  def create
    quiz = current_user.created_quizzes.find_by(id: params[:quiz_id])
    return head :forbidden unless quiz

    game = quiz.games.create!
    redirect_to game_path(game)
  end

  def start
    @game.with_stale_retry do |game|
      @game = game
      @game.start!
    end

    redirect_to game_path(@game)
  end

  def advance
    @game.with_stale_retry do |game|
      @game = game
      @game.advance!
    end

    redirect_to game_path(@game)
  end

  def finish_question
    @game.with_stale_retry do |game|
      @game = game
      @game.finish_question!
    end

    redirect_to game_path(@game)
  end

  private

  def set_game
    @game = Game.joins(:quiz).find_by(id: params[:id], quizzes: { creator_id: current_user.id })
    head :forbidden unless @game
  end
end
