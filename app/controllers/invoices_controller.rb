class InvoicesController < ApplicationController
  before_action :set_invoice, only: [ :show, :edit, :update, :destroy, :finalize_invoice, :send_invoice, :cancel_invoice, :mark_as_paid, :download_pdf ]

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
    unless @invoice.editable?
      return redirect_to @invoice, alert: "Impossible de modifier cette facture."
    end
    if @invoice.update(invoice_params)
      redirect_to @invoice, notice: "Facture mise à jour."
    else
      @clients = current_user.organization.clients
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @invoice.editable?
      return redirect_to @invoice, alert: "Impossible de supprimer cette facture."
    end
    @invoice.destroy
    redirect_to invoices_path, notice: "Facture supprimée."
  end

  def finalize_invoice
    if @invoice.finalizable?
      @invoice.update!(status: :finalized, finalized_at: Time.current)
      redirect_to @invoice, notice: "Facture finalisée."
    else
      redirect_to @invoice, alert: "Impossible de finaliser : brouillon vide ou statut incorrect."
    end
  end

  def send_invoice
    if @invoice.sendable?
      @invoice.update!(status: :sent, sent_at: Time.current)
      redirect_to @invoice, notice: "Facture envoyée."
    else
      redirect_to @invoice, alert: "Impossible d'envoyer cette facture."
    end
  end

  def cancel_invoice
    if @invoice.cancellable?
      @invoice.update!(status: :cancelled)
      redirect_to @invoice, notice: "Facture annulée."
    else
      redirect_to @invoice, alert: "Impossible d'annuler cette facture."
    end
  end

  def mark_as_paid
    if @invoice.payable?
      @invoice.update!(status: :paid)
      redirect_to @invoice, notice: "Facture marquée comme payée."
    else
      redirect_to @invoice, alert: "Impossible de marquer cette facture comme payée."
    end
  end

  def download_pdf
    unless @invoice.downloadable?
      return redirect_to @invoice, alert: "Le PDF n'est disponible qu'à partir de la finalisation."
    end
    pdf = InvoicePdfGenerator.call(@invoice)
    send_data pdf, filename: "facture_#{@invoice.number}.pdf", type: "application/pdf", disposition: "inline"
  end

  private

  def set_invoice
    @invoice = current_user.organization.invoices.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(:client_id, :issue_date, :due_date, :subject, :currency)
  end
end
