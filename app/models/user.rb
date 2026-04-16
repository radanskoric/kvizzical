class User < ApplicationRecord
  has_many :participants, dependent: :nullify, inverse_of: :user
  has_many :sessions, dependent: :destroy
  has_secure_password

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true

  before_create :generate_session_token

  private

  def generate_session_token
    self.session_token = SecureRandom.base58(24)
  end
end
