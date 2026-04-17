class QuizPreviewsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_quiz

  def show
  end

  def question
    @question = @quiz.question_at(params[:position].to_i)
    return head :not_found unless @question

    @answers = ordered_answers(@question)
    @timeout_answer_position = 1
  end

  def answer
    @question = @quiz.question_at(params[:position].to_i)
    return head :not_found unless @question

    @answers = ordered_answers(@question)
    @answer_position = params[:answer_position].to_i
    return head :not_found if @answer_position < 1 || @answer_position > @answers.size

    @selected_answer_position = params[:answered_index].presence&.to_i
    @selected_answer = answer_at(@selected_answer_position)
    @next_question = @quiz.question_at(@question.position + 1)
  end

  def end
  end

  private

    def set_quiz
      @quiz = Quiz.find_by(secret_preview_token: params[:secret_preview_token])
      head :not_found unless @quiz
    end

    def ordered_answers(question)
      question.answers.order(:id)
    end

    def answer_at(position)
      return if position.blank?

      @answers[position - 1]
    end
end
