require 'rails_helper'

RSpec.describe "Authentication", type: :request do
  describe "GET /login" do
    it "affiche le formulaire de connexion" do
      get new_session_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Connectez-vous")
    end
  end

  describe "POST /login" do
    let!(:user) { create(:user, email: "test@example.com", password: "password123") }

    context "avec des identifiants valides" do
      it "connecte l'utilisateur et redirige vers le dashboard" do
        post session_path, params: { email: "test@example.com", password: "password123" }

        expect(response).to redirect_to(root_path)
        expect(session[:user_id]).to eq(user.id)

        follow_redirect!  # suit la redirection vers /
        expect(response).to redirect_to(dashboard_path)  # / redirige vers /dashboard

        follow_redirect!  # suit la redirection vers /dashboard
        expect(response.body).to include("Tableau de bord - #{user.organization.name}")
        expect(flash[:notice]).to eq("Connexion réussie.")
      end
    end

    context "avec des identifiants invalides" do
      it "affiche une erreur et ne connecte pas" do
        post session_path, params: { email: "test@example.com", password: "mauvais" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(session[:user_id]).to be_nil
        expect(response.body).to include("Email ou mot de passe incorrect")
      end
    end
  end

  describe "DELETE /logout" do
    let!(:user) { create(:user) }

    before { post session_path, params: { email: user.email, password: "password123" } }

    it "déconnecte l'utilisateur" do
      delete destroy_session_path

      expect(response).to redirect_to(new_session_path)
      expect(session[:user_id]).to be_nil
    end
  end

  describe "GET /signup" do
    it "affiche le formulaire d'inscription" do
      get new_registration_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Créez votre compte")
    end
  end

  describe "POST /signup" do
    context "avec des données valides" do
      let(:valid_params) do
        {
          organization: { name: "Test SARL", email: "contact@test.com", invoice_prefix: "TST" },
          user: { first_name: "Jean", last_name: "Dupont", email: "jean@test.com",
                  password: "password123", password_confirmation: "password123" }
        }
      end

      it "crée l'organisation, l'utilisateur et connecte" do
        expect {
          post registration_path, params: valid_params
        }.to change(Organization, :count).by(1).and change(User, :count).by(1)

        expect(response).to redirect_to(root_path)

        user = User.last
        expect(user.role).to eq("owner")
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context "avec des données invalides" do
      let(:invalid_params) do
        {
          organization: { name: "", email: "invalid" },
          user: { first_name: "", last_name: "", email: "", password: "short" }
        }
      end

      it "ne crée rien et affiche les erreurs" do
        expect {
          post registration_path, params: invalid_params
        }.not_to change(Organization, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "Protection des pages" do
    describe "GET /dashboard" do
      context "sans être connecté" do
        it "redirige vers la page de login" do
          get dashboard_path
          expect(response).to redirect_to(new_session_path)
          expect(flash[:alert]).to include("Vous devez être connecté")
        end
      end

      context "en étant connecté" do
        let!(:organization) { create(:organization) }
        let!(:user) { create(:user, organization: organization) }

        before { post session_path, params: { email: user.email, password: "password123" } }

        it "affiche le dashboard" do
          get dashboard_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include(user.organization.name)
        end
      end
    end
  end
end
