class Client < ApplicationRecord
  belongs_to :organization

  enum :client_type, { individual: 0, professional: 1 }

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :client_type, presence: true
  validates :country, presence: true
  validates :siret, length: { is: 14 }, numericality: { only_integer: true }, allow_blank: true
end