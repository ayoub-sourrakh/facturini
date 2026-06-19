class ProfilesController < ApplicationController
  def show
  end

  def update
    if params[:section] == "organization" && (current_user.owner? || current_user.admin?)
      if current_user.organization.update(organization_params)
        redirect_to profile_path, notice: "Organisation mise à jour."
      else
        @organization_errors = true
        render :show, status: :unprocessable_entity
      end
    else
      return redirect_to profile_path, alert: "Accès non autorisé." unless params[:user]

      if params[:user][:password].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end

      if current_user.update(user_params)
        redirect_to profile_path, notice: "Profil mis à jour."
      else
        @user_errors = true
        render :show, status: :unprocessable_entity
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

  def organization_params
    params.require(:organization).permit(
      :name, :email, :phone, :address, :city, :zip_code, :country,
      :siret, :siren, :vat_number, :legal_form, :capital, :invoice_prefix
    )
  end
end
