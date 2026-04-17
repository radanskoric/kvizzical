class Question < ApplicationRecord
  belongs_to :quiz, inverse_of: :questions

  has_many :answers, dependent: :destroy, inverse_of: :question
  has_many :references, dependent: :destroy, inverse_of: :question
  has_many :responses, dependent: :destroy, inverse_of: :question

  validates :body, presence: true
  validates :position, presence: true
end
