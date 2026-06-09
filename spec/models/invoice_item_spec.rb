require 'rails_helper'

RSpec.describe InvoiceItem, type: :model do
  describe "validations" do
    subject { build(:invoice_item) }

    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).is_greater_than(0) }
    it { should validate_presence_of(:unit_price_cents) }
    it { should validate_numericality_of(:unit_price_cents).is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:vat_rate) }
    it { should validate_numericality_of(:vat_rate).is_greater_than_or_equal_to(0) }
  end

  describe "associations" do
    it { should belong_to(:invoice) }
  end
end