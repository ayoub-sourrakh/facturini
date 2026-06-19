class UsersController < ApplicationController
  before_action :require_owner_or_admin
  before_action :set_user, only: [ :edit, :update, :destroy ]

  def index
    if current_user.admin?
      @users = User.includes(:organization).order(created_at: :asc)
    else
      @users = current_user.organization.users.order(created_at: :asc)
    end
  end

  def new
    @user = current_user.admin? ? User.new : current_user.organization.users.build
  end

  def create
    @user = current_user.admin? ? User.new(user_params) : current_user.organization.users.build(user_params)
    assign_role(@user)

    if @user.save
      redirect_to users_path, notice: "Utilisateur créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    assign_role(@user)
    if @user.update(user_params)
      redirect_to users_path, notice: "Utilisateur mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to users_path, alert: "Vous ne pouvez pas supprimer votre propre compte."
    else
      @user.destroy
      redirect_to users_path, notice: "Utilisateur supprimé."
    end
  end

  private

  def require_owner_or_admin
    unless current_user.owner? || current_user.admin?
      redirect_to dashboard_path, alert: "Accès non autorisé."
    end
  end

  def set_user
    if current_user.admin?
      @user = User.find(params[:id])
    else
      @user = current_user.organization.users.find(params[:id])
    end
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

  def assign_role(user)
    return unless current_user.admin? || current_user.owner?
    return unless params[:user][:role].present?
    role = params[:user][:role]
    user.role = role if User.roles.key?(role)
  end
end
