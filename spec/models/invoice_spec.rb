require 'rails_helper'

RSpec.describe Invoice, type: :model do
  describe "validations" do
    subject { build(:invoice) }

    it { should validate_presence_of(:number) }
    it { should validate_uniqueness_of(:number).scoped_to(:organization_id) }
    it { should validate_presence_of(:issue_date) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:currency) }
  end

  describe "associations" do
    it { should belong_to(:organization) }
    it { should belong_to(:client) }
    it { should have_many(:invoice_items).dependent(:destroy) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values(draft: 0, finalized: 1, sent: 2, paid: 3, cancelled: 4) }
  end
end
