class Quiz < ApplicationRecord
  belongs_to :creator, class_name: "User", optional: true
  has_many :questions, -> { order(:position) }, dependent: :destroy, inverse_of: :quiz
  has_many :games, dependent: :destroy, inverse_of: :quiz

  validates :title, presence: true
end
