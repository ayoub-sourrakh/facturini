require 'rails_helper'

RSpec.describe Invoice, type: :model do
  describe "validations" do
    subject { build(:invoice) }

    it { should validate_presence_of(:issue_date) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:currency) }

    context "due_date" do
      it "n'est pas requis pour un brouillon" do
        invoice = build(:invoice, status: :draft, due_date: nil)
        expect(invoice).to be_valid
      end

      it "est requis pour une facture finalisée" do
        invoice = build(:invoice, status: :finalized, due_date: nil)
        expect(invoice).not_to be_valid
        expect(invoice.errors[:due_date]).to be_present
      end
    end
  end

  describe "associations" do
    it { should belong_to(:organization) }
    it { should belong_to(:client) }
    it { should have_many(:invoice_items).dependent(:destroy) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values(draft: 0, finalized: 1, sent: 2, paid: 3, cancelled: 4) }
  end

  describe "méthodes métier" do
    let(:invoice) { create(:invoice, status: :draft) }

    describe "#editable?" do
      it "retourne true pour un brouillon" do
        expect(invoice.editable?).to be true
      end

      it "retourne false pour une facture finalisée" do
        invoice.update!(status: :finalized)
        expect(invoice.editable?).to be false
      end
    end

    describe "#finalizable?" do
      it "retourne true avec lignes et due_date" do
        create(:invoice_item, invoice: invoice)
        invoice.update!(due_date: 30.days.from_now)
        expect(invoice.finalizable?).to be true
      end

      it "retourne false sans lignes" do
        invoice.update!(due_date: 30.days.from_now)
        expect(invoice.finalizable?).to be false
      end

      it "retourne false sans due_date" do
        create(:invoice_item, invoice: invoice)
        invoice.update_column(:due_date, nil)
        expect(invoice.finalizable?).to be false
      end

      it "retourne false si pas en brouillon" do
        create(:invoice_item, invoice: invoice)
        invoice.update!(status: :finalized)
        expect(invoice.finalizable?).to be false
      end
    end

    describe "#sendable?" do
      it "retourne true si finalisée" do
        invoice.update!(status: :finalized)
        expect(invoice.sendable?).to be true
      end

      it "retourne false si brouillon" do
        expect(invoice.sendable?).to be false
      end
    end

    describe "#cancellable?" do
      it "retourne true si finalisée" do
        invoice.update!(status: :finalized)
        expect(invoice.cancellable?).to be true
      end

      it "retourne false si envoyée" do
        invoice.update!(status: :sent)
        expect(invoice.cancellable?).to be false
      end
    end

    describe "#payable?" do
      it "retourne true si envoyée" do
        invoice.update!(status: :sent)
        expect(invoice.payable?).to be true
      end

      it "retourne false si finalisée" do
        invoice.update!(status: :finalized)
        expect(invoice.payable?).to be false
      end
    end

    describe "#downloadable?" do
      it "retourne true si finalisée" do
        invoice.update!(status: :finalized)
        expect(invoice.downloadable?).to be true
      end

      it "retourne true si envoyée" do
        invoice.update!(status: :sent)
        expect(invoice.downloadable?).to be true
      end

      it "retourne true si payée" do
        invoice.update!(status: :paid)
        expect(invoice.downloadable?).to be true
      end

      it "retourne false si brouillon" do
        expect(invoice.downloadable?).to be false
      end

      it "retourne false si annulée" do
        invoice.update!(status: :cancelled)
        expect(invoice.downloadable?).to be false
      end
    end
  end
end
