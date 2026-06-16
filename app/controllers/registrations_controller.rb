class RegistrationsController < ApplicationController
  # Seuls les admins peuvent créer des comptes
  before_action :require_admin, only: [ :new, :create ]

  layout "auth"

  def new
    @organization = Organization.new
    @user = User.new
  end

  def create
    @organization = Organization.new(organization_params)
    @user = @organization.users.build(user_params.merge(role: :owner))

    ActiveRecord::Base.transaction do
      @organization.save!
      @user.save!
    end

    start_session(@user)
    redirect_to root_path, notice: "Bienvenue sur Facturini !"
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Accès réservé aux administrateurs"
    end
  end

  def organization_params
    params.require(:organization).permit(:name, :email, :invoice_prefix)
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end
end
