class InvoiceMailer < ApplicationMailer
  def send_invoice(invoice)
    @invoice = invoice
    @organization = invoice.organization
    @client = invoice.client

    pdf = InvoicePdfGenerator.call(invoice)

    attachments["facture_#{invoice.number}.pdf"] = {
      mime_type: "application/pdf",
      content: pdf
    }

    mail(
      to: @client.email,
      subject: "Facture #{invoice.number} — #{@organization.name}"
    )
  end
end
