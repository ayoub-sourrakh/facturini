require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  let!(:org) { create(:organization) }
  let!(:owner) { create(:user, :owner, organization: org) }
  let!(:member) { create(:user, organization: org) }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password123" }
  end

  describe "GET /profile" do
    context "sans être connecté" do
      it "redirige vers le login" do
        get profile_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "en étant connecté" do
      it "affiche les infos de l'utilisateur" do
        sign_in(member)
        get profile_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include(member.first_name)
        expect(response.body).to include(member.email)
      end

      it "affiche la section organisation pour le owner" do
        sign_in(owner)
        get profile_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include(org.name)
        expect(response.body).to include("Mon organisation")
      end

      it "n'affiche pas la section organisation pour le member" do
        sign_in(member)
        get profile_path
        expect(response.body).not_to include("Mon organisation")
      end
    end
  end

  describe "PATCH /profile (section user)" do
    before { sign_in(member) }

    it "met à jour les infos personnelles" do
      patch profile_path, params: {
        section: "user",
        user: { first_name: "Nouveau", last_name: "Nom", email: member.email }
      }
      expect(response).to redirect_to(profile_path)
      expect(member.reload.first_name).to eq("Nouveau")
    end

    it "met à jour le mot de passe si fourni" do
      patch profile_path, params: {
        section: "user",
        user: {
          first_name: member.first_name, last_name: member.last_name,
          email: member.email, password: "newpassword123",
          password_confirmation: "newpassword123"
        }
      }
      expect(response).to redirect_to(profile_path)
      expect(member.reload.authenticate("newpassword123")).to be_truthy
    end
  end

  describe "PATCH /profile (section organization)" do
    context "en tant que owner" do
      before { sign_in(owner) }

      it "met à jour les infos de l'organisation" do
        patch profile_path, params: {
          section: "organization",
          organization: {
            name: "Nouveau Nom Org", email: org.email,
            invoice_prefix: org.invoice_prefix, country: "FR"
          }
        }
        expect(response).to redirect_to(profile_path)
        expect(org.reload.name).to eq("Nouveau Nom Org")
      end
    end

    context "en tant que member" do
      before { sign_in(member) }

      it "ne met pas à jour l'organisation et redirige" do
        patch profile_path, params: {
          section: "organization",
          organization: { name: "Hacked", email: org.email, invoice_prefix: "HCK", country: "FR" }
        }
        expect(response).to redirect_to(profile_path)
        expect(org.reload.name).not_to eq("Hacked")
      end
    end
  end
end
