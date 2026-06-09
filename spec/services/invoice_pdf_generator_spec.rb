require 'rails_helper'

RSpec.describe InvoicePdfGenerator do
  let!(:organization) { create(:organization, name: "Ma Société") }
  let!(:client) { create(:client, organization: organization, name: "Client Test") }
  let!(:invoice) { create(:invoice, organization: organization, client: client, number: "INV-001") }
  
  before do
    create(:invoice_item, invoice: invoice, description: "Produit A", quantity: 2, unit_price_cents: 5000, vat_rate: 20)
    create(:invoice_item, invoice: invoice, description: "Produit B", quantity: 1, unit_price_cents: 10000, vat_rate: 20)
    InvoiceCalculator.call(invoice)
  end

  describe ".call" do
    it "génère un PDF valide" do
      pdf = described_class.call(invoice)
      expect(pdf).to be_a(String)
      expect(pdf).to start_with("%PDF")
    end

    it "génère un document non vide" do
      pdf = described_class.call(invoice)
      expect(pdf.length).to be > 100  # Vérifie que le PDF a du contenu
    end
  end
end