class ClientsController < ApplicationController
  before_action :require_organization
  before_action :set_client, only: [ :show, :edit, :update, :destroy ]

  def index
    @clients = current_user.organization.clients.order(name: :asc)
  end

  def show
  end

  def new
    @client = current_user.organization.clients.build
  end

  def create
    @client = current_user.organization.clients.build(client_params)

    if @client.save
      redirect_to @client, notice: "Client créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to @client, notice: "Client mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to clients_path, notice: "Client supprimé."
  end

  private

  def set_client
    @client = current_user.organization.clients.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :email, :phone, :address, :city, :zip_code,
                                   :country, :siret, :vat_number, :client_type)
  end
end
