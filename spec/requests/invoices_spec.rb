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
      it "crée une facture en brouillon avec un numéro auto-généré" do
        expect {
          post invoices_path, params: {
            invoice: {
              client_id: client.id,
              issue_date: Date.today,
              subject: "Test facture"
            }
          }
        }.to change(Invoice, :count).by(1)

        created = Invoice.last
        expect(created.status).to eq("draft")
        expect(created.number).to match(/\A[A-Z]{3}-\d{3}\z/)
        expect(created.number).to start_with(organization.invoice_prefix)
        expect(response).to redirect_to(invoice_path(created))
      end

      it "incrémente le numéro pour chaque nouvelle facture" do
        post invoices_path, params: { invoice: { client_id: client.id, issue_date: Date.today } }
        post invoices_path, params: { invoice: { client_id: client.id, issue_date: Date.today } }

        numbers = Invoice.last(2).map(&:number)
        seq = numbers.map { |n| n.split("-").last.to_i }
        expect(seq.last).to eq(seq.first + 1)
      end
    end

    context "avec des paramètres invalides" do
      it "ne crée pas de facture" do
        expect {
          post invoices_path, params: { invoice: { client_id: nil } }
        }.not_to change(Invoice, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /invoices/:id/edit" do
    it "affiche le formulaire d'édition pour un brouillon" do
      get edit_invoice_path(invoice)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /invoices/:id" do
    context "facture en brouillon" do
      it "met à jour la facture" do
        patch invoice_path(invoice), params: { invoice: { subject: "Nouvel objet" } }
        expect(response).to redirect_to(invoice_path(invoice))
        expect(invoice.reload.subject).to eq("Nouvel objet")
      end
    end

    context "facture finalisée" do
      let!(:finalized_invoice) { create(:invoice, organization: organization, client: client, status: :finalized) }

      it "ne peut pas modifier une facture finalisée" do
        patch invoice_path(finalized_invoice), params: { invoice: { subject: "Tentative" } }
        expect(response).to redirect_to(invoice_path(finalized_invoice))
        expect(finalized_invoice.reload.subject).not_to eq("Tentative")
      end
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
      let!(:finalized_invoice) { create(:invoice, organization: organization, client: client, status: :finalized) }

      it "ne supprime pas la facture" do
        expect {
          delete invoice_path(finalized_invoice)
        }.not_to change(Invoice, :count)
        expect(response).to redirect_to(invoice_path(finalized_invoice))
      end
    end

    context "facture envoyée" do
      let!(:sent_invoice) { create(:invoice, organization: organization, client: client, status: :sent) }

      it "ne supprime pas la facture" do
        expect {
          delete invoice_path(sent_invoice)
        }.not_to change(Invoice, :count)
        expect(response).to redirect_to(invoice_path(sent_invoice))
      end
    end
  end

  describe "PATCH /invoices/:id/finalize_invoice" do
    context "brouillon avec lignes et date d'échéance" do
      let!(:draft_invoice) { create(:invoice, organization: organization, client: client, status: :draft, due_date: 30.days.from_now) }
      let!(:item) { create(:invoice_item, invoice: draft_invoice) }

      it "finalise la facture" do
        patch finalize_invoice_invoice_path(draft_invoice)
        draft_invoice.reload
        expect(draft_invoice.status).to eq("finalized")
        expect(draft_invoice.finalized_at).to be_present
        expect(response).to redirect_to(invoice_path(draft_invoice))
      end
    end

    context "brouillon sans lignes" do
      let!(:empty_invoice) { create(:invoice, organization: organization, client: client, status: :draft, due_date: 30.days.from_now) }

      it "refuse de finaliser" do
        patch finalize_invoice_invoice_path(empty_invoice)
        expect(empty_invoice.reload.status).to eq("draft")
        expect(response).to redirect_to(invoice_path(empty_invoice))
      end
    end

    context "brouillon sans date d'échéance" do
      let!(:invoice_no_due) { create(:invoice, organization: organization, client: client, status: :draft, due_date: nil) }
      let!(:item) { create(:invoice_item, invoice: invoice_no_due) }

      it "refuse de finaliser" do
        patch finalize_invoice_invoice_path(invoice_no_due)
        expect(invoice_no_due.reload.status).to eq("draft")
        expect(response).to redirect_to(invoice_path(invoice_no_due))
      end
    end
  end

  describe "PATCH /invoices/:id/send_invoice" do
    context "facture finalisée" do
      let!(:finalized_invoice) { create(:invoice, organization: organization, client: client, status: :finalized) }

      it "marque la facture comme envoyée" do
        patch send_invoice_invoice_path(finalized_invoice)
        finalized_invoice.reload
        expect(finalized_invoice.status).to eq("sent")
        expect(finalized_invoice.sent_at).to be_present
        expect(response).to redirect_to(invoice_path(finalized_invoice))
      end

      it "enfile un email au client" do
        expect {
          patch send_invoice_invoice_path(finalized_invoice)
        }.to have_enqueued_mail(InvoiceMailer, :send_invoice)
      end

      it "le notice confirme l'email du client" do
        patch send_invoice_invoice_path(finalized_invoice)
        expect(flash[:notice]).to include(client.email)
      end
    end

    context "facture en brouillon" do
      let!(:draft_invoice) { create(:invoice, organization: organization, client: client, status: :draft) }

      it "ne peut pas envoyer un brouillon" do
        patch send_invoice_invoice_path(draft_invoice)
        expect(draft_invoice.reload.status).to eq("draft")
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
  end

  describe "PATCH /invoices/:id/cancel_invoice" do
    context "facture finalisée" do
      let!(:finalized_invoice) { create(:invoice, organization: organization, client: client, status: :finalized) }

      it "annule la facture" do
        patch cancel_invoice_invoice_path(finalized_invoice)
        expect(finalized_invoice.reload.status).to eq("cancelled")
        expect(response).to redirect_to(invoice_path(finalized_invoice))
      end
    end

    context "facture envoyée" do
      let!(:sent_invoice) { create(:invoice, organization: organization, client: client, status: :sent) }

      it "ne peut pas annuler une facture envoyée" do
        patch cancel_invoice_invoice_path(sent_invoice)
        expect(sent_invoice.reload.status).to eq("sent")
        expect(response).to redirect_to(invoice_path(sent_invoice))
      end
    end
  end

  describe "PATCH /invoices/:id/mark_as_paid" do
    context "facture envoyée" do
      let!(:sent_invoice) { create(:invoice, organization: organization, client: client, status: :sent) }

      it "marque la facture comme payée" do
        patch mark_as_paid_invoice_path(sent_invoice)
        expect(sent_invoice.reload.status).to eq("paid")
        expect(response).to redirect_to(invoice_path(sent_invoice))
      end
    end

    context "facture finalisée" do
      let!(:finalized_invoice) { create(:invoice, organization: organization, client: client, status: :finalized) }

      it "ne peut pas marquer comme payée sans envoi" do
        patch mark_as_paid_invoice_path(finalized_invoice)
        expect(finalized_invoice.reload.status).to eq("finalized")
        expect(response).to redirect_to(invoice_path(finalized_invoice))
      end
    end
  end

  describe "GET /invoices/:id/download_pdf" do
    context "facture finalisée avec lignes" do
      let!(:finalized_invoice) { create(:invoice, organization: organization, client: client, status: :finalized) }
      let!(:item) { create(:invoice_item, invoice: finalized_invoice) }

      before { InvoiceCalculator.call(finalized_invoice) }

      it "télécharge le PDF" do
        get download_pdf_invoice_path(finalized_invoice)
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("application/pdf")
        expect(response.headers["Content-Disposition"]).to include("facture_#{finalized_invoice.number}.pdf")
        expect(response.body).to start_with("%PDF")
      end
    end

    context "facture en brouillon" do
      it "refuse de télécharger le PDF" do
        get download_pdf_invoice_path(invoice)
        expect(response).to redirect_to(invoice_path(invoice))
      end
    end
  end
end
