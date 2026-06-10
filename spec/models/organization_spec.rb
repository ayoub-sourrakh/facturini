require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe "validations" do
    subject { build(:organization) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:country) }
    it "valide l'unicité de l'email" do
      create(:organization, email: "test@example.com")
      duplicate = build(:organization, email: "test@example.com")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end
    it { should validate_uniqueness_of(:siret).case_insensitive }
    it { should validate_uniqueness_of(:vat_number) }
    it { should validate_length_of(:siret).is_equal_to(14) }
    it { should validate_length_of(:siren).is_equal_to(9) }
  end

  describe "associations" do
    it { should have_many(:users).dependent(:destroy) }
    it { should have_many(:clients).dependent(:destroy) }
    it { should have_many(:invoices).dependent(:destroy) }
  end
end
