require 'rails_helper'

RSpec.describe "Organizations", type: :request do
  let!(:org) { create(:organization) }
  let!(:admin) { create(:user, :admin, organization: org) }
  let!(:owner) { create(:user, :owner, organization: org) }
  let!(:member) { create(:user, organization: org) }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password123" }
  end

  describe "GET /organizations" do
    context "en tant que member" do
      it "redirige vers le dashboard" do
        sign_in(member)
        get organizations_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context "en tant que owner" do
      it "redirige vers le dashboard" do
        sign_in(owner)
        get organizations_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context "en tant que admin" do
      it "affiche toutes les organisations" do
        sign_in(admin)
        get organizations_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include(org.name)
      end
    end
  end

  describe "POST /organizations" do
    context "en tant que admin" do
      before { sign_in(admin) }

      it "crée une organisation" do
        expect {
          post organizations_path, params: { organization: {
            name: "Nouvelle Org", email: "org@example.com",
            invoice_prefix: "NVO", country: "FR"
          } }
        }.to change(Organization, :count).by(1)
      end

      it "assigne le owner sélectionné" do
        new_user = create(:user, :without_org)

        post organizations_path, params: {
          owner_id: new_user.id,
          organization: {
            name: "Nouvelle Org", email: "org@example.com",
            invoice_prefix: "NVO", country: "FR"
          }
        }

        new_user.reload
        expect(new_user.organization).to eq(Organization.last)
        expect(new_user.role).to eq("owner")
      end
    end
  end

  describe "DELETE /organizations/:id" do
    context "en tant que admin" do
      before { sign_in(admin) }

      it "supprime l'organisation et ses membres en cascade" do
        other_org = create(:organization)
        create(:user, :owner, organization: other_org)

        expect {
          delete organization_path(other_org)
        }.to change(Organization, :count).by(-1)
          .and change(User, :count).by(-1)
      end
    end
  end
end
