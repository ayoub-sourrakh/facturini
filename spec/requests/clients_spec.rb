require 'rails_helper'

RSpec.describe "Clients", type: :request do
  let!(:organization) { create(:organization) }
  let!(:user) { create(:user, organization: organization) }
  let!(:client) { create(:client, organization: organization, name: "Acme Corp") }

  before do
    post session_path, params: { email: user.email, password: user.password }
  end

  describe "GET /clients" do
    it "affiche la liste des clients" do
      get clients_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Acme Corp")
    end
  end

  describe "GET /clients/:id" do
    it "affiche le détail du client" do
      get client_path(client)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Acme Corp")
    end
  end

  describe "POST /clients" do
    it "crée un client" do
      expect {
        post clients_path, params: {
          client: {
            name: "Nouveau Client",
            email: "client@test.com",
            client_type: "professional"
          }
        }
      }.to change(Client, :count).by(1)

      expect(response).to redirect_to(client_path(Client.last))
    end

    it "rejette un client sans nom" do
      expect {
        post clients_path, params: { client: { name: "", email: "test@test.com" } }
      }.not_to change(Client, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /clients/:id" do
    it "met à jour le client" do
      patch client_path(client), params: {
        client: { name: "Acme Updated", phone: "0123456789" }
      }
      expect(response).to redirect_to(client_path(client))
      expect(client.reload.name).to eq("Acme Updated")
      expect(client.phone).to eq("0123456789")
    end
  end

  describe "DELETE /clients/:id" do
    it "supprime le client" do
      expect {
        delete client_path(client)
      }.to change(Client, :count).by(-1)

      expect(response).to redirect_to(clients_path)
    end
  end
end