class PasswordResetsController < ApplicationController
  skip_before_action :require_authentication
  layout false

  def new
  end

  def create
    @user = User.find_by(email: params[:email])
    if @user
      @user.generate_password_reset_token!
      UserMailer.password_reset(@user).deliver_later
    end
    redirect_to new_session_path, notice: "Si cet email existe, vous recevrez les instructions."
  end

  def edit
    @user = User.find_by(reset_password_token: params[:id])
    redirect_to new_password_reset_path, alert: "Lien invalide ou expiré." unless @user&.reset_password_sent_at&.after?(2.hours.ago)
  end

  def update
    @user = User.find_by(reset_password_token: params[:id])
    if @user.nil? || @user.reset_password_sent_at.before?(2.hours.ago)
      redirect_to new_password_reset_path, alert: "Lien invalide ou expiré."
    elsif params[:user][:password].blank?
      flash.now[:alert] = "Le mot de passe ne peut pas être vide."
      render :edit
    elsif @user.update(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation])
      @user.update(reset_password_token: nil, reset_password_sent_at: nil)
      redirect_to new_session_path, notice: "Mot de passe réinitialisé avec succès."
    else
      render :edit
    end
  end
end