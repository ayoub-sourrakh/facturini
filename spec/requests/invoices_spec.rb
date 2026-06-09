require 'rails_helper'

RSpec.describe "Invoices", type: :request do
  let!(:organization) { create(:organization) }
  let!(:user) { create(:user, organization: organization) }
  let!(:client) { create(:client, organization: organization) }
  let!(:invoice) { create(:invoice, organization: organization, client: client) }

  before do
    post session_path, params: { email: user.email, password: user.password }
  end

  describe "GET /invoices" do
    it "affiche la liste des factures" do
      get invoices_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(invoice.number)
    end
  end

  describe "GET /invoices/:id" do
    it "affiche le détail d'une facture" do
      get invoice_path(invoice)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(invoice.number)
      expect(response.body).to include(client.name)
    end
  end

  describe "GET /invoices/new" do
    it "affiche le formulaire de création" do
      get new_invoice_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /invoices" do
    context "avec des paramètres valides" do
      it "crée une facture" do
        expect {
          post invoices_path, params: {
            invoice: {
              number: "INV-002",
              client_id: client.id,
              issue_date: Date.today,
              due_date: Date.today + 30.days,
              subject: "Test facture"
            }
          }
        }.to change(Invoice, :count).by(1)

        expect(response).to redirect_to(invoice_path(Invoice.last))
      end
    end

    context "avec des paramètres invalides" do
      it "ne crée pas de facture" do
        expect {
          post invoices_path, params: { invoice: { number: "", client_id: nil } }
        }.not_to change(Invoice, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /invoices/:id/edit" do
    it "affiche le formulaire d'édition" do
      get edit_invoice_path(invoice)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /invoices/:id" do
    it "met à jour la facture" do
      patch invoice_path(invoice), params: {
        invoice: { subject: "Nouvel objet" }
      }
      expect(response).to redirect_to(invoice_path(invoice))
      expect(invoice.reload.subject).to eq("Nouvel objet")
    end
  end

  describe "DELETE /invoices/:id" do
    context "facture en brouillon" do
      let!(:draft_invoice) { create(:invoice, organization: organization, client: client, status: :draft) }

      it "supprime la facture" do
        expect {
          delete invoice_path(draft_invoice)
        }.to change(Invoice, :count).by(-1)

        expect(response).to redirect_to(invoices_path)
      end
    end

    context "facture finalisée" do
      let!(:sent_invoice) { create(:invoice, organization: organization, client: client, status: :sent) }

      it "ne supprime pas la facture" do
        expect {
          delete invoice_path(sent_invoice)
        }.not_to change(Invoice, :count)

        expect(response).to redirect_to(invoice_path(sent_invoice))
      end
    end
  end

  describe "PATCH /invoices/:id/send_invoice" do
    context "facture en brouillon avec lignes" do
      let!(:draft_invoice) { create(:invoice, organization: organization, client: client, status: :draft) }
      let!(:item) { create(:invoice_item, invoice: draft_invoice) }

      it "marque la facture comme envoyée" do
        patch send_invoice_invoice_path(draft_invoice)

        draft_invoice.reload
        expect(draft_invoice.status).to eq("sent")
        expect(draft_invoice.sent_at).to be_present

        expect(response).to redirect_to(invoice_path(draft_invoice))
      end
    end

    context "facture déjà envoyée" do
      let!(:sent_invoice) { create(:invoice, organization: organization, client: client, status: :sent) }

      it "ne change pas le statut" do
        patch send_invoice_invoice_path(sent_invoice)

        expect(sent_invoice.reload.status).to eq("sent")
        expect(response).to redirect_to(invoice_path(sent_invoice))
      end
    end

    context "facture sans lignes" do
      let!(:empty_invoice) { create(:invoice, organization: organization, client: client, status: :draft) }

      it "refuse d'envoyer une facture vide" do
        patch send_invoice_invoice_path(empty_invoice)

        expect(empty_invoice.reload.status).to eq("draft")
        expect(response).to redirect_to(invoice_path(empty_invoice))
      end
    end
  end

  describe "GET /invoices/:id/download_pdf" do
    let!(:item) { create(:invoice_item, invoice: invoice) }

    before { InvoiceCalculator.call(invoice) }

    it "télécharge le PDF" do
      get download_pdf_invoice_path(invoice)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("facture_#{invoice.number}.pdf")
      expect(response.body).to start_with("%PDF")
    end
  end
end
