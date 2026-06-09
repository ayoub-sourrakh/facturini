Rails.application.routes.draw do
  # Auth
  get "login", to: "sessions#new", as: :new_session
  post "login", to: "sessions#create", as: :session
  delete "logout", to: "sessions#destroy", as: :destroy_session

  # Registration
  get "signup", to: "registrations#new", as: :new_registration
  post "signup", to: "registrations#create", as: :registration

  # Dashboard (protégé)
  get "dashboard", to: "dashboard#index", as: :dashboard

  # Invoices (CRUD complet)
  resources :invoices

  # Clients (CRUD complet)
  resources :clients

  # Invoice items (CRUD complet)
  resources :invoices do
    resources :invoice_items, only: [:create, :destroy]
    member do
      patch :send_invoice
      get :download_pdf
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root redirige vers dashboard si connecté, sinon login
  root to: redirect("/dashboard")
end