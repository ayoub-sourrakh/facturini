class DashboardController < ApplicationController
  def index
    @organization = current_user.organization
    @invoices_count = @organization.invoices.count
    @clients_count = @organization.clients.count
  end
end
