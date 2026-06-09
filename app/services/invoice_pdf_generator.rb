class InvoicePdfGenerator
  require "prawn/table"
  
  def self.call(invoice)
    new(invoice).call
  end

  def initialize(invoice)
    @invoice = invoice
    @organization = invoice.organization
    @client = invoice.client
  end

  def call
    Prawn::Document.new do |pdf|
      # En-tête
      pdf.text @organization.name, size: 20, style: :bold
      pdf.text "Facture #{@invoice.number}", size: 16, style: :bold, color: "3366CC"
      pdf.move_down 20

      # Infos client
      pdf.text "Client :", style: :bold
      pdf.text @client.name
      pdf.text @client.email if @client.email
      pdf.text @client.address if @client.address
      pdf.text "#{@client.zip_code} #{@client.city}" if @client.zip_code || @client.city
      pdf.move_down 20

      # Dates
      pdf.text "Date d'émission : #{I18n.l @invoice.issue_date}"
      pdf.text "Date d'échéance : #{I18n.l @invoice.due_date}" if @invoice.due_date
      pdf.text "Objet : #{@invoice.subject}" if @invoice.subject
      pdf.move_down 20

      # Tableau des lignes
      if @invoice.invoice_items.any?
        data = [["Description", "Qté", "Prix unit.", "TVA %", "Total"]]
        
        @invoice.invoice_items.each do |item|
          line_total = (item.quantity * item.unit_price_cents).round
          data << [
            item.description,
            item.quantity,
            format_money(item.unit_price_cents),
            "#{item.vat_rate}%",
            format_money(line_total)
          ]
        end

        pdf.table(data, header: true, width: pdf.bounds.width) do
          row(0).font_style = :bold
          row(0).background_color = "F0F0F0"
          cells.padding = 5
        end

        pdf.move_down 20

        # Totaux
        pdf.text "Total HT : #{format_money(@invoice.subtotal_cents)}", align: :right
        pdf.text "TVA : #{format_money(@invoice.vat_amount_cents)}", align: :right
        pdf.text "Total TTC : #{format_money(@invoice.total_cents)}", align: :right, style: :bold, size: 14
      end

      # Footer
      pdf.move_down 40
      pdf.text "Cette facture a été générée automatiquement.", size: 9, color: "666666"
    end.render
  end

  private

  def format_money(cents)
    "€ #{(cents / 100.0).round(2)}"
  end
end