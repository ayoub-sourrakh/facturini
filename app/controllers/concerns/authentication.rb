module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :current_user, :signed_in?
  end

  private

  def signed_in?
    current_user.present?
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_authentication
    unless signed_in?
      redirect_to new_session_path, alert: "Vous devez être connecté pour accéder à cette page."
    end
  end

  def require_organization
    if signed_in? && current_user.organization.nil? && !current_user.admin?
      redirect_to dashboard_path, alert: "Votre compte n'est associé à aucune organisation."
    end
  end

  def start_session(user)
    session[:user_id] = user.id
  end

  def end_session
    session.delete(:user_id)
    @current_user = nil
  end
end
