class Quiz < ApplicationRecord
  belongs_to :creator, class_name: "User", optional: true
  has_many :questions, -> { order(:position) }, dependent: :destroy, inverse_of: :quiz
  has_many :games, dependent: :destroy, inverse_of: :quiz

  before_validation :ensure_secret_preview_token, on: :create

  validates :title, presence: true
  validates :secret_preview_token, presence: true, uniqueness: true

  def question_at(position)
    questions.find_by(position: position)
  end

  private

  def ensure_secret_preview_token
    return if secret_preview_token.present?

    loop do
      self.secret_preview_token = SecureRandom.urlsafe_base64(18)
      break unless self.class.exists?(secret_preview_token: secret_preview_token)
    end
  end
end
