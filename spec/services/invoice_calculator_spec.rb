require 'rails_helper'

RSpec.describe InvoiceCalculator, type: :service do
  describe ".call" do
    let(:organization) { create(:organization) }
    let(:client) { create(:client, organization: organization) }
    let(:invoice) { create(:invoice, organization: organization, client: client) }

    context "avec des lignes de facture" do
      before do
        # Ligne 1: 2h × 50€ HT = 100€ HT + 20€ TVA = 120€ TTC
        create(:invoice_item, invoice: invoice, quantity: 2, unit_price_cents: 5000, vat_rate: 20)

        # Ligne 2: 1.5h × 80€ HT = 120€ HT + 24€ TVA = 144€ TTC
        create(:invoice_item, invoice: invoice, quantity: 1.5, unit_price_cents: 8000, vat_rate: 20)
      end

      it "calcule correctement le sous-total HT" do
        InvoiceCalculator.call(invoice)

        # 100€ + 120€ = 220€ = 22000 cents
        expect(invoice.reload.subtotal_cents).to eq(22000)
      end

      it "calcule correctement la TVA" do
        InvoiceCalculator.call(invoice)

        # 20€ + 24€ = 44€ = 4400 cents
        expect(invoice.reload.vat_amount_cents).to eq(4400)
      end

      it "calcule correctement le total TTC" do
        InvoiceCalculator.call(invoice)

        # 220€ + 44€ = 264€ = 26400 cents
        expect(invoice.reload.total_cents).to eq(26400)
      end
    end

    context "sans lignes de facture" do
      it "met les totaux à zéro" do
        InvoiceCalculator.call(invoice)

        expect(invoice.reload.subtotal_cents).to eq(0)
        expect(invoice.reload.vat_amount_cents).to eq(0)
        expect(invoice.reload.total_cents).to eq(0)
      end
    end

    context "avec une facture non persistée" do
      let(:new_invoice) { build(:invoice, organization: organization, client: client) }

      it "ne fait rien et retourne nil" do
        result = InvoiceCalculator.call(new_invoice)

        expect(result).to be_nil
        expect(new_invoice.subtotal_cents).to eq(0) # valeur par défaut, pas calculée
      end
    end
  end
end
