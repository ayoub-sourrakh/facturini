require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe "#password_reset" do
    let(:user) { create(:user) }
    let(:mail) { UserMailer.password_reset(user) }

    before do
      user.generate_password_reset_token!
    end

    it "envoie à l'email de l'utilisateur" do
      expect(mail.to).to eq([ user.email ])
    end

    it "a le bon sujet" do
      expect(mail.subject).to eq("Réinitialisation de votre mot de passe")
    end

    it "contient le prénom de l'utilisateur" do
      expect(mail.text_part.decoded).to include(user.first_name)
      expect(mail.html_part.decoded).to include(user.first_name)
    end

    it "contient le lien de réinitialisation avec le token" do
      expect(mail.body.encoded).to include("/password_resets/")
      expect(mail.body.encoded).to include("/edit")
    end

    it "a les versions texte et html" do
      expect(mail.content_type).to include("multipart/alternative")
      expect(mail.text_part.body.encoded).to include(user.first_name)
      expect(mail.html_part.body.encoded).to include(user.first_name)
    end
  end
end
