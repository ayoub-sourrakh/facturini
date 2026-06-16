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

  describe "#generate_password_reset_token!" do
    let(:user) { create(:user) }

    it "génère un token unique" do
      expect {
        user.generate_password_reset_token!
      }.to change { user.reset_password_token }.from(nil).to(String)
    end

    it "enregistre la date d'envoi" do
      before_time = Time.current
      user.generate_password_reset_token!
      expect(user.reset_password_sent_at).to be >= before_time
      expect(user.reset_password_sent_at).to be <= Time.current
    end

  end
end
