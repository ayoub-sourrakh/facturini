class OrganizationsController < ApplicationController
  before_action :require_admin
  before_action :set_organization, only: [ :show, :edit, :update, :destroy ]

  def index
    @organizations = Organization.includes(:users).order(created_at: :desc)
  end

  def show
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      if params[:owner_id].present?
        owner = User.find_by(id: params[:owner_id])
        owner&.update(organization: @organization, role: :owner)
      end
      redirect_to organizations_path, notice: "Organisation créée avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @organization.update(organization_params)
      if params[:owner_id].present?
        new_owner = User.find_by(id: params[:owner_id])
        if new_owner && new_owner != @organization.users.find_by(role: :owner)
          @organization.users.where(role: :owner).update_all(role: :member)
          new_owner.update(organization: @organization, role: :owner)
        end
      end
      redirect_to organizations_path, notice: "Organisation mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @organization.destroy
    redirect_to organizations_path, notice: "Organisation supprimée."
  end

  private

  def require_admin
    unless current_user.admin?
      redirect_to dashboard_path, alert: "Accès non autorisé."
    end
  end

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(
      :name, :email, :phone, :address, :city, :zip_code, :country,
      :siret, :siren, :vat_number, :legal_form, :capital, :invoice_prefix
    )
  end
end
