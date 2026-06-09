require 'rails_helper'

RSpec.describe "InvoiceItems", type: :request do
  let!(:organization) { create(:organization) }
  let!(:user) { create(:user, organization: organization) }
  let!(:client) { create(:client, organization: organization) }
  let!(:invoice) { create(:invoice, organization: organization, client: client) }

  before do
    post session_path, params: { email: user.email, password: user.password }
  end

  describe "POST /invoices/:invoice_id/invoice_items" do
    it "ajoute une ligne et recalcule les totaux" do
      expect {
        post invoice_invoice_items_path(invoice), params: {
          invoice_item: {
            description: "Prestation",
            quantity: 2,
            unit_price_cents: 5000,  # 50€
            vat_rate: 20
          }
        }
      }.to change(invoice.invoice_items, :count).by(1)

      invoice.reload
      expect(invoice.subtotal_cents).to eq(10000)  # 2 × 50€ = 100€
      expect(invoice.vat_amount_cents).to eq(2000)  # 20% de 100€ = 20€
      expect(invoice.total_cents).to eq(12000)  # 120€ TTC

      expect(response).to redirect_to(invoice_path(invoice))
    end
  end

  describe "DELETE /invoices/:invoice_id/invoice_items/:id" do
    let!(:item) do
      create(:invoice_item, invoice: invoice, quantity: 1, unit_price_cents: 10000, vat_rate: 20)
    end

    before do
      InvoiceCalculator.call(invoice)  # Initialise les totaux
    end

    it "supprime la ligne et recalcule" do
      expect(invoice.reload.total_cents).to be > 0

      expect {
        delete invoice_invoice_item_path(invoice, item)
      }.to change(invoice.invoice_items, :count).by(-1)

      invoice.reload
      expect(invoice.total_cents).to eq(0)

      expect(response).to redirect_to(invoice_path(invoice))
    end
  end
end
