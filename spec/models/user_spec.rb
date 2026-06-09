require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_presence_of(:role) }
    it { should have_secure_password }
  end

  describe "associations" do
    it { should belong_to(:organization) }
  end

  describe "enums" do
    it { should define_enum_for(:role).with_values(member: 0, admin: 1, owner: 2) }
  end
end