class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :destroy, :send_invoice, :download_pdf]

  def index
    @invoices = current_user.organization.invoices.order(created_at: :desc)
  end

  def show
  end

  def new
    @invoice = current_user.organization.invoices.build
    @clients = current_user.organization.clients
  end

  def create
    @invoice = current_user.organization.invoices.build(invoice_params)

    if @invoice.save
      redirect_to @invoice, notice: "Facture créée en brouillon."
    else
      @clients = current_user.organization.clients
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @clients = current_user.organization.clients
  end

  def update
    if @invoice.draft?
      if @invoice.update(invoice_params)
        InvoiceCalculator.call(@invoice) if @invoice.invoice_items.any?
        redirect_to @invoice, notice: "Facture mise à jour."
      else
        @clients = current_user.organization.clients
        render :edit, status: :unprocessable_entity
      end
    else
      redirect_to @invoice, alert: "Impossible de modifier une facture envoyée."
    end
  end

  def destroy
    if @invoice.draft?
      @invoice.destroy
      redirect_to invoices_path, notice: "Facture supprimée."
    else
      redirect_back fallback_location: invoice_path(@invoice), alert: "Impossible de supprimer une facture finalisée."
    end
  end

  def send_invoice
    if @invoice.draft? && @invoice.invoice_items.any?
      @invoice.update!(status: :sent, sent_at: Time.current)
      redirect_to @invoice, notice: "Facture envoyée au client."
    else
      redirect_to @invoice, alert: "Impossible d'envoyer : facture vide ou déjà envoyée."
    end
  end

  def download_pdf
    pdf = InvoicePdfGenerator.call(@invoice)
    send_data pdf, filename: "facture_#{@invoice.number}.pdf", type: "application/pdf", disposition: "inline"
  end

  private

  def set_invoice
    @invoice = current_user.organization.invoices.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(:number, :client_id, :issue_date, :due_date, :subject, :currency)
  end
end