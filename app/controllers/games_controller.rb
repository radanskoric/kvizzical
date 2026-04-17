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
    @game.start!
    redirect_to game_path(@game)
  end

  def advance
    @game.advance!
    redirect_to game_path(@game)
  end

  def finish_question
    @game.finish_question!
    redirect_to game_path(@game)
  end

  private

  def set_game
    @game = Game.joins(:quiz).find_by(id: params[:id], quizzes: { creator_id: current_user.id })
    head :forbidden unless @game
  end
end
