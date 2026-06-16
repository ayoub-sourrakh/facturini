class User < ApplicationRecord
  belongs_to :organization

  has_secure_password

  enum :role, { member: 0, admin: 1, owner: 2 }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true

  def generate_password_reset_token!
    self.reset_password_token = SecureRandom.urlsafe_base64(32)
    self.reset_password_sent_at = Time.current
    save(validate: false)
  end
end
