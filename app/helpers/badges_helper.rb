module BadgesHelper
  STATUS_BADGE_CLASSES = {
    "draft"     => "bg-gray-100 text-gray-700",
    "finalized" => "bg-indigo-100 text-indigo-700",
    "sent"      => "bg-green-100 text-green-700",
    "paid"      => "bg-violet-100 text-violet-700",
    "cancelled" => "bg-red-100 text-red-700"
  }.freeze

  STATUS_LABELS = {
    "draft"     => "Brouillon",
    "finalized" => "Finalisée",
    "sent"      => "Envoyée",
    "paid"      => "Payée",
    "cancelled" => "Annulée"
  }.freeze

  def invoice_status_badge_class(invoice)
    STATUS_BADGE_CLASSES[invoice.status] || "bg-gray-100 text-gray-700"
  end

  def invoice_status_label(invoice)
    STATUS_LABELS[invoice.status] || invoice.status.humanize
  end
end
