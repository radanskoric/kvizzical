class GamesController < ApplicationController
  before_action :set_game, except: [ :create ]

  def show
  end

  def create
    quiz = Quiz.find(params[:quiz_id])
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
    @game = Game.find(params[:id])
  end
end
