class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: [ :new, :create ]

  layout "auth"

  def new
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      start_session(user)
      redirect_to root_path, notice: "Connexion réussie."
    else
      flash.now[:alert] = "Email ou mot de passe incorrect."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    end_session
    redirect_to new_session_path, notice: "Déconnexion réussie."
  end
end
