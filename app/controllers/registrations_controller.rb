class RegistrationsController < ApplicationController
  skip_before_action :require_authentication

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
    flash.now[:alert] = "Erreur lors de l'inscription."
    render :new, status: :unprocessable_entity
  end

  private

  def organization_params
    params.require(:organization).permit(:name, :email)
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end
end