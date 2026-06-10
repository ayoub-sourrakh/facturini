class Invoice < ApplicationRecord
  belongs_to :organization
  belongs_to :client
  has_many :invoice_items, dependent: :destroy

  enum :status, { draft: 0, finalized: 1, sent: 2, paid: 3, cancelled: 4 }

  before_create :set_invoice_number

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

  private

  def set_invoice_number
    prefix = organization.invoice_prefix
    last = organization.invoices.maximum("CAST(SPLIT_PART(number, '-', 2) AS INTEGER)") || 0
    self.number = "#{prefix}-#{(last + 1).to_s.rjust(3, '0')}"
  end
end
