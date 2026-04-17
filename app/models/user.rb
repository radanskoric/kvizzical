class User < ApplicationRecord
  has_many :created_quizzes, class_name: "Quiz", foreign_key: :creator_id, dependent: :nullify, inverse_of: :creator
  has_many :participants, dependent: :nullify, inverse_of: :user
  has_many :sessions, dependent: :destroy
  has_secure_password validations: false

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true, if: :registered?
  validates :password, presence: true, confirmation: true, if: :password_required?

  before_create :generate_session_token

  def registered?
    email_address.present?
  end

  private

    def password_required?
      registered? && (new_record? || password.present? || password_confirmation.present?)
    end

    def generate_session_token
      self.session_token = SecureRandom.base58(24)
    end
end
