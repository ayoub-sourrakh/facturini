class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :invoices, dependent: :destroy

  before_validation :normalize_unique_fields

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { message: "déjà utilisé" }, format: { with: URI::MailTo::EMAIL_REGEXP, message: "invalide" }
  validates :siret, uniqueness: true, allow_blank: true, length: { is: 14 }, numericality: { only_integer: true }
  validates :siren, allow_blank: true, length: { is: 9 }, numericality: { only_integer: true }
  validates :vat_number, uniqueness: true, allow_blank: true
  validates :country, presence: true
  validates :capital, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :invoice_prefix, presence: true,
                           length: { is: 3 },
                           format: { with: /\A[A-Z]{3}\z/, message: "doit contenir exactement 3 lettres majuscules" }

  private

  def normalize_unique_fields
    self.siret = siret.presence
    self.siren = siren.presence
    self.vat_number = vat_number.presence
  end
end
