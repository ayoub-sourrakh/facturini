require 'rails_helper'

RSpec.describe "Password Resets", type: :request do
  let(:user) { create(:user) }

  describe "GET /password_resets/new" do
    it "affiche le formulaire" do
      get new_password_reset_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /password_resets" do
    context "avec un email existant" do
      it "génère un token et envoie l'email" do
        expect {
          post password_resets_path, params: { email: user.email }
        }.to change { user.reload.reset_password_token }.from(nil).to(String)
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to include("Si cet email existe")
      end

      it "envoie l'email en background" do
        expect {
          post password_resets_path, params: { email: user.email }
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end

    context "avec un email inexistant" do
      it "redirige quand même (sécurité)" do
        post password_resets_path, params: { email: "inexistant@test.com" }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to include("Si cet email existe")
      end
    end
  end

  describe "GET /password_resets/:id/edit" do
    context "avec un token valide" do
      before do
        user.generate_password_reset_token!
      end

      it "affiche le formulaire de nouveau mot de passe" do
        get edit_password_reset_path(user.reset_password_token)
        expect(response).to have_http_status(:ok)
      end
    end

    context "avec un token invalide" do
      it "redirige vers new" do
        get edit_password_reset_path("token_invalide")
        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to include("Lien invalide ou expiré")
      end
    end

    context "avec un token expiré" do
      before do
        user.update(reset_password_token: "ancien", reset_password_sent_at: 3.hours.ago)
      end

      it "redirige vers new" do
        get edit_password_reset_path("ancien")
        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to include("Lien invalide ou expiré")
      end
    end
  end

  describe "PATCH /password_resets/:id" do
    before do
      user.generate_password_reset_token!
    end

    context "avec un mot de passe valide" do
      it "met à jour le mot de passe" do
        patch password_reset_path(user.reset_password_token), params: {
          user: { password: "nouveau123", password_confirmation: "nouveau123" }
        }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to include("réinitialisé avec succès")
        expect(user.reload.authenticate("nouveau123")).to be_truthy
      end

      it "efface le token" do
        patch password_reset_path(user.reset_password_token), params: {
          user: { password: "nouveau123", password_confirmation: "nouveau123" }
        }
        expect(user.reload.reset_password_token).to be_nil
      end
    end

    context "avec un mot de passe vide" do
      it "affiche une erreur" do
        patch password_reset_path(user.reset_password_token), params: {
          user: { password: "", password_confirmation: "" }
        }
        expect(response).to have_http_status(:ok)
        expect(flash[:alert]).to include("ne peut pas être vide")
      end
    end

    context "avec des mots de passe différents" do
      it "affiche une erreur" do
        patch password_reset_path(user.reset_password_token), params: {
          user: { password: "nouveau123", password_confirmation: "different123" }
        }
        expect(response).to have_http_status(:ok)
        expect(user.reload.authenticate("nouveau123")).to be_falsey
      end
    end

    context "avec un token expiré" do
      before do
        user.update(reset_password_sent_at: 3.hours.ago)
      end

      it "redirige avec une erreur" do
        patch password_reset_path(user.reset_password_token), params: {
          user: { password: "nouveau123", password_confirmation: "nouveau123" }
        }
        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to include("Lien invalide ou expiré")
      end
    end
  end
end
