class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :check_maintenance_mode

  private

  def check_maintenance_mode
    if ENV["MAINTENANCE_MODE"] == "true"
      render file: Rails.public_path.join("maintenance.html"), layout: false, status: :service_unavailable
    end
  end
end
