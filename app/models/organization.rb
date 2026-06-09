class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :invoices, dependent: :destroy
  
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :siret, uniqueness: true, allow_blank: true, length: { is: 14 }, numericality: { only_integer: true }
  validates :siren, allow_blank: true, length: { is: 9 }, numericality: { only_integer: true }
  validates :vat_number, uniqueness: true, allow_blank: true
  validates :country, presence: true
  validates :capital, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end