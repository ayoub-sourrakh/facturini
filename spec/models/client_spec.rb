require 'rails_helper'

RSpec.describe Client, type: :model do
  describe "validations" do
    subject { build(:client) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:client_type) }
    it { should validate_presence_of(:country) }
    it { should validate_length_of(:siret).is_equal_to(14) }
  end

  describe "associations" do
    it { should belong_to(:organization) }
  end

  describe "enums" do
    it { should define_enum_for(:client_type).with_values(individual: 0, professional: 1) }
  end
end