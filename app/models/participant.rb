class Participant < ApplicationRecord
  belongs_to :game, inverse_of: :participants
  belongs_to :user, optional: true, inverse_of: :participants

  has_many :responses, dependent: :destroy, inverse_of: :participant

  validates :user_id, uniqueness: { scope: :game_id }, allow_nil: true

  def name
    user&.name || "Anonymous"
  end
end
