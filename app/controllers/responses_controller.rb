class ResponsesController < ApplicationController
  allow_unauthenticated_access

  def create
    game = Game.find_by!(code: params[:game_code])
    user = current_player_user
    participant = game.participants.find_by(user: user)

    if game.active? && participant && within_deadline?(game)
      response = participant.responses.build(
        question_id: params[:question_id],
        answer_id: params[:answer_id],
        responded_at: Time.current
      )

      if response.save
        game = game.reload

        game.with_stale_retry do |current_game|
          game = current_game
          if game.all_answered?
            game.finish_question!
          else
            game.broadcast_game_state
          end
        end
      end
    end

    redirect_to play_path(code: game.code)
  end

  private

  def within_deadline?(game)
    return false unless game.question_opened_at

    question = Question.find_by(id: params[:question_id])
    return false unless question

    Time.current <= game.question_opened_at + question.time_limit_seconds.seconds
  end
end
