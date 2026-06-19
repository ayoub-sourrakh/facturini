require 'rails_helper'

RSpec.describe "Users", type: :request do
  let!(:org) { create(:organization) }
  let!(:admin) { create(:user, :admin, organization: org) }
  let!(:owner) { create(:user, :owner, organization: org) }
  let!(:member) { create(:user, organization: org) }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password123" }
  end

  describe "GET /users" do
    context "en tant que member" do
      it "redirige vers le dashboard" do
        sign_in(member)
        get users_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context "en tant que owner" do
      it "affiche uniquement les users de son organisation" do
        other_org = create(:organization)
        create(:user, organization: other_org)

        sign_in(owner)
        get users_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include(owner.first_name)
        expect(response.body).not_to include(other_org.name)
      end
    end

    context "en tant que admin" do
      it "affiche tous les users" do
        other_org = create(:organization)
        other_user = create(:user, organization: other_org)

        sign_in(admin)
        get users_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include(other_user.first_name)
        expect(response.body).to include("Organisation")
      end
    end
  end

  describe "POST /users" do
    context "en tant que owner" do
      before { sign_in(owner) }

      it "crée un user dans son organisation" do
        expect {
          post users_path, params: { user: {
            first_name: "Jean", last_name: "Dupont",
            email: "jean@example.com", password: "password123",
            password_confirmation: "password123", role: "member"
          } }
        }.to change(User, :count).by(1)

        new_user = User.last
        expect(new_user.organization).to eq(org)
      end
    end

    context "en tant que admin" do
      before { sign_in(admin) }

      it "crée un user sans organisation" do
        expect {
          post users_path, params: { user: {
            first_name: "Jean", last_name: "Dupont",
            email: "jean@example.com", password: "password123",
            password_confirmation: "password123", role: "member"
          } }
        }.to change(User, :count).by(1)

        expect(User.last.organization).to be_nil
      end
    end
  end

  describe "POST /users — scoping organisation" do
    context "en tant que owner" do
      before { sign_in(owner) }

      it "force l'organisation du owner sur le nouvel user" do
        post users_path, params: { user: {
          first_name: "Jean", last_name: "Dupont",
          email: "jean@example.com", password: "password123",
          password_confirmation: "password123", role: "member"
        } }
        expect(User.find_by(email: "jean@example.com").organization).to eq(org)
      end

      it "ne peut pas créer un user sans organisation" do
        post users_path, params: { user: {
          first_name: "Jean", last_name: "Dupont",
          email: "jean2@example.com", password: "password123",
          password_confirmation: "password123", role: "member"
        } }
        expect(User.find_by(email: "jean2@example.com").organization).not_to be_nil
      end
    end

    context "en tant que admin" do
      before { sign_in(admin) }

      it "peut créer un user sans organisation" do
        post users_path, params: { user: {
          first_name: "Jean", last_name: "Dupont",
          email: "jean@example.com", password: "password123",
          password_confirmation: "password123", role: "member"
        } }
        expect(User.find_by(email: "jean@example.com").organization).to be_nil
      end
    end
  end

  describe "GET/DELETE /users/:id — isolation entre organisations" do
    let!(:other_org) { create(:organization) }
    let!(:other_user) { create(:user, organization: other_org) }

    context "en tant que owner" do
      before { sign_in(owner) }

      it "ne peut pas éditer un user d'une autre organisation" do
        get edit_user_path(other_user)
        expect(response).to have_http_status(:not_found).or redirect_to(dashboard_path)
      end

      it "ne peut pas supprimer un user d'une autre organisation" do
        expect {
          delete user_path(other_user)
        }.not_to change(User, :count)
      end
    end
  end

  describe "Protection des pages nécessitant une organisation" do
    let!(:user_without_org) { create(:user, :without_org, role: :member) }

    before { post session_path, params: { email: user_without_org.email, password: "password123" } }

    it "redirige vers dashboard avec un message si accès à clients sans org" do
      get clients_path
      expect(response).to redirect_to(dashboard_path)
      expect(flash[:alert]).to be_present
    end

    it "redirige vers dashboard avec un message si accès à invoices sans org" do
      get invoices_path
      expect(response).to redirect_to(dashboard_path)
      expect(flash[:alert]).to be_present
    end

    it "redirige vers dashboard avec un message si accès au dashboard sans org" do
      get dashboard_path
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "DELETE /users/:id" do
    context "en tant que owner" do
      before { sign_in(owner) }

      it "supprime un user de son organisation" do
        expect {
          delete user_path(member)
        }.to change(User, :count).by(-1)
      end

      it "ne peut pas se supprimer lui-même" do
        expect {
          delete user_path(owner)
        }.not_to change(User, :count)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
