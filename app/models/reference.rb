class Reference < ApplicationRecord
  belongs_to :question, inverse_of: :references

  validates :url, presence: true
end
