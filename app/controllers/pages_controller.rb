class PagesController < ApplicationController
  skip_before_action :require_authentication
  layout "landing"

  def home
    redirect_to dashboard_path if signed_in?
  end

  def terms
  end

  def privacy
  end

  def legal
  end
end
