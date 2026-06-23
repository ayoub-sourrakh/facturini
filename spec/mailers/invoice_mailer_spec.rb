require 'rails_helper'

RSpec.describe InvoiceMailer, type: :mailer do
  let!(:organization) { create(:organization) }
  let!(:client) { create(:client, organization: organization) }
  let!(:invoice) { create(:invoice, :finalized, organization: organization, client: client) }
  let(:mail) { InvoiceMailer.send_invoice(invoice) }

  describe "#send_invoice" do
    it "envoie au bon destinataire (email du client)" do
      expect(mail.to).to eq([ client.email ])
    end

    it "expédie depuis l'adresse Facturini" do
      expect(mail.from).to eq([ "noreply@facturini.fr" ])
    end

    it "a le bon sujet avec le numéro de facture et le nom de l'organisation" do
      expect(mail.subject).to include(invoice.number)
      expect(mail.subject).to include(organization.name)
    end

    it "contient le numéro de facture dans le corps HTML" do
      expect(mail.html_part.decoded).to include(invoice.number)
    end

    it "contient le nom du client dans le corps HTML" do
      expect(mail.html_part.decoded).to include(client.name)
    end

    it "contient le numéro de facture dans la version texte" do
      expect(mail.text_part.decoded).to include(invoice.number)
    end

    it "est de type multipart/mixed (avec pièce jointe)" do
      expect(mail.content_type).to include("multipart/mixed")
    end

    it "contient une pièce jointe PDF" do
      attachment = mail.attachments.first
      expect(attachment).not_to be_nil
      expect(attachment.filename).to eq("facture_#{invoice.number}.pdf")
      expect(attachment.content_type).to include("application/pdf")
    end

    it "la pièce jointe est un PDF valide (commence par %PDF)" do
      pdf_content = mail.attachments.first.decoded
      expect(pdf_content).to start_with("%PDF")
    end
  end
end
