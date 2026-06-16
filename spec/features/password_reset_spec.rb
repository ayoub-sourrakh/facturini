require 'rails_helper'

RSpec.feature "Password Reset", type: :feature do
  let!(:user) { create(:user) }

  scenario "un utilisateur réinitialise son mot de passe" do
    # 1. Va sur la page de connexion
    visit new_session_path

    # 2. Clique sur "Mot de passe oublié"
    click_link "Mot de passe oublié"

    # 3. Remplit son email
    fill_in "Email", with: user.email
    click_button "Envoyer les instructions"

    # 4. Vérifie le message de confirmation
    expect(page).to have_content("Si cet email existe")

    # 5. Récupère le token de l'email envoyé
    user.reload
    expect(user.reset_password_token).not_to be_nil

    # 6. Visite le lien du token
    visit edit_password_reset_path(user.reset_password_token)

    # 7. Remplit le nouveau mot de passe
    fill_in "Nouveau mot de passe", with: "nouveau123"
    fill_in "Confirmation", with: "nouveau123"
    click_button "Réinitialiser"

    # 8. Vérifie la redirection vers login
    expect(page).to have_current_path(new_session_path)
    expect(page).to have_content("réinitialisé avec succès")

    # 9. Se connecte avec le nouveau mot de passe
    fill_in "Email", with: user.email
    fill_in "Mot de passe", with: "nouveau123"
    click_button "Se connecter"

    # 10. Vérifie qu'il est connecté (redirigé vers dashboard)
    expect(page).to have_current_path(dashboard_path)
  end

  scenario "un token invalide redirige vers la page de demande" do
    visit edit_password_reset_path("token_invalide")
    expect(page).to have_content("Lien invalide ou expiré")
    expect(page).to have_current_path(new_password_reset_path)
  end
end
