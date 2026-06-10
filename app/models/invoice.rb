class Invoice < ApplicationRecord
  belongs_to :organization
  belongs_to :client
  has_many :invoice_items, dependent: :destroy

  enum :status, { draft: 0, finalized: 1, sent: 2, paid: 3, cancelled: 4 }

  validates :number, presence: true, uniqueness: { scope: :organization_id }
  validates :issue_date, presence: true
  validates :status, presence: true
  validates :currency, presence: true
  validates :due_date, presence: true, unless: :draft?

  def editable?
    draft?
  end

  def finalizable?
    draft? && invoice_items.any? && due_date.present?
  end

  def sendable?
    finalized?
  end

  def cancellable?
    finalized?
  end

  def payable?
    sent?
  end

  def downloadable?
    finalized? || sent? || paid?
  end
end
