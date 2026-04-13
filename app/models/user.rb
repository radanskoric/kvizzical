class User < ApplicationRecord
  has_many :participants, dependent: :nullify, inverse_of: :user

  validates :name, presence: true

  before_create :generate_session_token

  private

  def generate_session_token
    self.session_token = SecureRandom.base58(24)
  end
end
