class InvoiceItemsController < ApplicationController
  before_action :set_invoice

  def create
    if @invoice.draft?
      @item = @invoice.invoice_items.build(item_params)
      if @item.save
        InvoiceCalculator.call(@invoice)
        redirect_to @invoice, notice: "Ligne ajoutée."
      else
        redirect_to @invoice, alert: "Erreur lors de l'ajout."
      end
    else
      redirect_to @invoice, alert: "Impossible de modifier une facture envoyée."
    end
  end

  def destroy
    if @invoice.draft?
      @item = @invoice.invoice_items.find(params[:id])
      @item.destroy
      InvoiceCalculator.call(@invoice)
      redirect_to @invoice, notice: "Ligne supprimée."
    else
      redirect_to @invoice, alert: "Impossible de modifier une facture envoyée."
    end
  end

  private

  def set_invoice
    @invoice = current_user.organization.invoices.find(params[:invoice_id])
  end

  def item_params
    params.require(:invoice_item).permit(:description, :quantity, :unit_price_cents, :vat_rate)
  end
end