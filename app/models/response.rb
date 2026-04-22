class Response < ApplicationRecord
  belongs_to :participant, inverse_of: :responses, touch: true
  belongs_to :question
  belongs_to :answer

  validates :responded_at, presence: true
  validates :participant_id, uniqueness: { scope: :question_id }

  before_validation :calculate_score, on: :create

  private

  def calculate_score
    return self.score = 0 unless answer&.correct?

    game = participant&.game
    return self.score = 0 unless game&.question_opened_at && question

    time_limit = question.time_limit_seconds.to_f
    elapsed = (responded_at - game.question_opened_at).to_f
    time_remaining = [ time_limit - elapsed, 0 ].max

    self.score = ((time_remaining / time_limit) * 600 + 400).round
  end
end
