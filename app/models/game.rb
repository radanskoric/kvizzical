class Game < ApplicationRecord
  belongs_to :quiz, inverse_of: :games
  belongs_to :current_question, class_name: "Question", optional: true

  has_many :participants, dependent: :destroy, inverse_of: :game

  enum :status, { waiting: 0, active: 1, finished: 2, reviewing: 3 }

  before_create :generate_code

  def start!
    return unless waiting?

    first_question = quiz.questions.order(:position).first
    update!(status: :active, current_question: first_question, question_opened_at: Time.current)
    broadcast_game_state
  end

  def finish_question!
    return unless active?

    update!(status: :reviewing, question_opened_at: nil)
    broadcast_game_state
  end

  def advance!
    return unless reviewing?

    next_question = quiz.questions.order(:position).where("position > ?", current_question.position).first

    if next_question
      update!(status: :active, current_question: next_question, question_opened_at: Time.current)
    else
      update!(status: :finished, current_question: nil, question_opened_at: nil)
    end
    broadcast_game_state
  end

  def all_answered?
    return false unless active? && current_question

    participants.count > 0 &&
      current_question.responses.where(participant: participants).count >= participants.count
  end

  def broadcast_game_state
    broadcast_replace_to(
      self,
      target: "game_host_area",
      partial: "games/host_area",
      locals: { game: self }
    )

    participants.each do |participant|
      next unless participant.user_id

      broadcast_replace_to(
        "game_#{id}_player_#{participant.user_id}",
        target: "player_game_area",
        partial: "play/game_area",
        locals: { game: self, participant: participant }
      )
    end
  end

  def broadcast_player_list
    broadcast_replace_to(
      self,
      target: "player_list",
      partial: "games/player_list",
      locals: { game: self }
    )
  end

  private

  def generate_code
    return if code.present?

    loop do
      self.code = SecureRandom.alphanumeric(6).upcase
      break unless Game.exists?(code: code)
    end
  end
end
