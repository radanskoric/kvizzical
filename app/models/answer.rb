class Answer < ApplicationRecord
  belongs_to :question, inverse_of: :answers
  has_many :responses, dependent: :destroy, inverse_of: :answer

  validates :body, presence: true
  validates :correct, uniqueness: { scope: :question_id, conditions: -> { where(correct: true) }, message: "has already been taken" }, if: :correct?
end
