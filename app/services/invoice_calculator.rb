class InvoiceCalculator
  def self.call(invoice)
    new(invoice).call
  end

  def initialize(invoice)
    @invoice = invoice
  end

  def call
    return unless @invoice.persisted?

    items = @invoice.invoice_items.to_a

    subtotal_cents = items.sum do |item|
      (item.quantity * item.unit_price_cents).round
    end

    vat_amount_cents = items.sum do |item|
      line_total = (item.quantity * item.unit_price_cents).round
      (line_total * (item.vat_rate / 100)).round
    end

    total_cents = subtotal_cents + vat_amount_cents

    @invoice.update!(
      subtotal_cents: subtotal_cents,
      vat_amount_cents: vat_amount_cents,
      total_cents: total_cents
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Invoice calculation failed for invoice ##{@invoice.id}: #{e.message}"
    false
  end
end