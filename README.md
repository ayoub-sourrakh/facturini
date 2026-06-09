# Facturini

Application SaaS B2B de facturation multi-tenancy construite avec Ruby on Rails 8. MVP fonctionnel avec authentification, gestion de clients et factures, calculs automatiques, génération PDF et un design system cohérent.

## Stack Technique

| Catégorie | Technologie |
|-----------|-------------|
| **Framework** | Ruby on Rails 8.0 |
| **Ruby** | 3.3.4 |
| **Base de données** | PostgreSQL |
| **CSS** | Tailwind CSS |
| **Icônes** | Heroicons (SVG inline) |
| **Authentification** | `has_secure_password` + sessions |
| **PDF** | Prawn + prawn-table |
| **Tests** | RSpec, FactoryBot, Shoulda Matchers |

## Architecture

### Principes appliqués

- **Service Objects** — Logique métier isolée dans `app/services/` (`InvoiceCalculator`, `InvoicePdfGenerator`)
- **Thin Controllers** — Les contrôleurs gèrent uniquement le cycle HTTP (params, flash, redirections)
- **Multi-tenancy** — Toutes les données scopées par `Organization`, aucun accès cross-tenant possible
- **RESTful** — Routes `resources` standard Rails + routes `member` pour les actions custom
- **Workflow Guards** — Contrôleurs et vues protègent les factures envoyées contre toute modification
- **DRY Layouts** — Deux layouts distincts (`application` pour l'app, `auth` pour login/signup)
- **Design System** — Composants visuels uniformes (cards, inputs, boutons, badges, icônes)

### Structure du projet

```
app/
├── controllers/
│   ├── concerns/
│   │   └── authentication.rb       # Module session/current_user/require_auth
│   ├── application_controller.rb   # Inclut Authentication
│   ├── sessions_controller.rb      # Login/Logout (layout: auth)
│   ├── registrations_controller.rb # Inscription (layout: auth)
│   ├── dashboard_controller.rb     # Tableau de bord
│   ├── clients_controller.rb       # CRUD Clients
│   ├── invoices_controller.rb      # CRUD Factures + send_invoice + download_pdf
│   └── invoice_items_controller.rb # Ajout/suppression de lignes
├── models/
│   ├── organization.rb             # Tenant principal
│   ├── user.rb                     # has_secure_password, enum role
│   ├── client.rb                   # enum client_type
│   ├── invoice.rb                  # enum status, workflow methods
│   └── invoice_item.rb             # Lignes de facture
├── services/
│   ├── invoice_calculator.rb       # Calcul HT, TVA, TTC en centimes
│   └── invoice_pdf_generator.rb    # Génération PDF avec Prawn
├── helpers/
│   └── icons_helper.rb             # Heroicons SVG inline via helper
├── views/
│   ├── layouts/
│   │   ├── application.html.erb    # Layout principal (sidebar + content)
│   │   └── auth.html.erb           # Layout authentification (centré)
│   ├── sessions/                   # Login
│   ├── registrations/              # Inscription
│   ├── dashboard/                  # Tableau de bord
│   ├── clients/                    # Index, Show, New, Edit
│   └── invoices/                   # Index, Show, New, Edit
└── assets/
    └── tailwind/application.css    # Point d'entrée Tailwind
```

## Fonctionnalités

### Authentification
- **Inscription** — Création simultanée d'une Organization et d'un User (owner) dans une transaction
- **Login/Logout** — Authentification par email/mot de passe avec session cookie
- **Protection** — `before_action :require_authentication` sur toutes les pages sauf login/signup
- **Layout dédié** — Pages auth avec layout centré (`auth.html.erb`), sans sidebar

### Clients (CRUD complet)
- Création, lecture, modification, suppression
- Champs : nom, email, téléphone, adresse, ville, code postal, pays, SIRET
- Types : **Particulier** / **Professionnel** (enum `client_type`)
- Scoped à l'organization de l'utilisateur connecté

### Factures (CRUD + Workflow)
- CRUD complet avec workflow de statuts :
  - **`draft`** (Brouillon) — Modifiable, supprimable, lignes éditables
  - **`sent`** (Envoyée) — Lecture seule, date d'envoi enregistrée, PDF uniquement
- Numéro de facture unique par organization
- Dates d'émission et d'échéance
- Objet/description optionnel
- Actions : Envoyer, Télécharger PDF, Modifier, Supprimer

### Lignes de facture (Invoice Items)
- Ajout/suppression dynamique depuis la page show de la facture
- Champs : description, quantité, prix unitaire (en centimes), taux de TVA (%)
- **Recalcul automatique** des totaux à chaque ajout/suppression via `InvoiceCalculator`

### Calculs automatiques (`InvoiceCalculator`)
- **Total HT** = Σ (quantité × prix unitaire) par ligne
- **TVA** = Σ (total_ligne × taux_tva / 100) par ligne
- **Total TTC** = HT + TVA
- Stockage en **centimes (integer)** pour éviter les erreurs d'arrondi float
- Appelé automatiquement depuis `InvoicesController` et `InvoiceItemsController`

### Génération PDF (`InvoicePdfGenerator`)
- Génération avec Prawn + prawn-table
- Contenu : informations organization, client, détails facture, tableau des lignes, totaux
- Téléchargement via `send_data` au format `facture-{numero}.pdf`

### Dashboard
- Vue tableau de bord avec compteurs : nombre de factures et de clients
- Liens rapides vers les listes

## Design System

### Layouts
- **`application.html.erb`** — Sidebar fixe (256px) + zone de contenu principale avec flash messages centralisées
- **`auth.html.erb`** — Layout centré verticalement/horizontalement, fond `gray-50`, max-width 448px

### Composants visuels

| Composant | Classes Tailwind |
|-----------|-----------------|
| **Card** | `bg-white shadow-sm rounded-xl border border-gray-200` |
| **Input** | `border-gray-300 rounded-lg shadow-sm text-sm focus:ring-2 focus:ring-indigo-500` |
| **Label** | `text-sm font-medium text-gray-700 mb-1` |
| **Bouton principal** | `bg-indigo-600 rounded-lg text-sm font-medium hover:bg-indigo-700 transition` |
| **Bouton danger** | `bg-red-50 text-red-600 rounded-lg hover:bg-red-100` |
| **Bouton secondaire** | `bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200` |
| **Badge** | `rounded-full text-xs font-medium` (gris/vert/indigo selon contexte) |
| **Table** | Card avec `overflow-hidden`, `divide-y`, hover sur les lignes |
| **Erreurs** | `bg-red-50 border-red-200 text-red-700 rounded-lg text-sm` |

### Icônes (Heroicons)
Icônes SVG inline via `IconsHelper` — usage : `<%= icon("eye") %>`

| Icône | Utilisation |
|-------|------------|
| `chart-bar` | Sidebar — Tableau de bord |
| `document-text` | Sidebar — Factures |
| `users` | Sidebar — Clients |
| `arrow-right-on-rectangle` | Sidebar — Déconnexion |
| `eye` | Listes — Voir |
| `pencil-square` | Listes + Show — Modifier |
| `trash` | Listes + Show — Supprimer |
| `arrow-down-tray` | Show facture — Télécharger PDF |
| `paper-airplane` | Show facture — Envoyer |
| `arrow-left` | Pages détail — Retour |
| `x-mark` | Show facture — Supprimer une ligne |

### Navigation
- **Sidebar** avec liens actifs highlight (indigo) via `current_page?` et `request.path`
- **Section utilisateur** en bas de sidebar (nom, organization, bouton déconnexion)

## Modèles & Relations

```
Organization
├── has_many :users
├── has_many :clients
└── has_many :invoices

User (belongs_to :organization)
├── has_secure_password
└── enum role: { member: 0, admin: 1 }

Client (belongs_to :organization)
└── enum client_type: { individual: 0, professional: 1 }

Invoice (belongs_to :organization, :client)
├── has_many :invoice_items (dependent: :destroy)
├── enum status: { draft: 0, sent: 1, paid: 2 }
└── Totaux calculés par InvoiceCalculator

InvoiceItem (belongs_to :invoice)
└── Champs : description, quantity, unit_price_cents, vat_rate
```

## Routes

```ruby
# Auth
GET/POST   /login        → sessions#new/create
DELETE     /logout       → sessions#destroy
GET/POST   /signup       → registrations#new/create

# App
GET        /dashboard    → dashboard#index

# CRUD
resources :clients                           # 7 routes standard
resources :invoices do                       # 7 routes standard +
  resources :invoice_items, only: [:create, :destroy]  # lignes nested
  member do
    patch :send_invoice                      # PATCH /invoices/:id/send_invoice
    get   :download_pdf                      # GET   /invoices/:id/download_pdf
  end
end

root → redirect("/dashboard")
```

## Sécurité

### Authentification
- `has_secure_password` (bcrypt) pour le hashing des mots de passe
- Session cookie pour maintenir la connexion
- `before_action :require_authentication` sur tous les controllers (sauf auth)
- Token CSRF sur tous les formulaires

### Multi-tenancy
Toutes les requêtes sont scopées à l'organization de l'utilisateur connecté :
```ruby
current_user.organization.invoices.find(params[:id])
current_user.organization.clients.find(params[:id])
```
Aucune donnée d'une autre organization n'est accessible.

### Workflow des factures
Une facture marquée comme **envoyée** devient en lecture seule :
- Modification bloquée (contrôleur + UI)
- Ajout/suppression de lignes bloqué
- Suppression de la facture bloquée
- Seul le téléchargement PDF reste disponible

## Installation

```bash
git clone https://github.com/votre-user/facturini.git
cd facturini

bundle install

rails db:create db:migrate

bin/dev
```

L'application est accessible sur `http://localhost:3000`.

## Tests

```bash
# Lancer tous les tests
bundle exec rspec

# Avec détail
bundle exec rspec --format documentation
```

### Couverture des tests

| Catégorie | Fichier | Ce qui est testé |
|-----------|---------|-----------------|
| **Request specs** | `spec/requests/authentication_spec.rb` | Login, logout, inscription, protection des pages |
| **Request specs** | `spec/requests/clients_spec.rb` | CRUD clients, validations, scoping |
| **Request specs** | `spec/requests/invoices_spec.rb` | CRUD factures, workflow, PDF, restrictions |
| **Request specs** | `spec/requests/invoice_items_spec.rb` | Ajout/suppression lignes, recalcul totaux |
| **Service specs** | `spec/services/invoice_calculator_spec.rb` | Calculs HT, TVA, TTC |
| **Service specs** | `spec/services/invoice_pdf_generator_spec.rb` | Génération binaire PDF |

## Roadmap

- [ ] Envoi de factures par email (ActionMailer + PJ PDF)
- [ ] Statut "Payée" avec date de paiement
- [ ] Dashboard avancé (CA mensuel, factures impayées, graphiques)
- [ ] Pagination des listes (Pagy)
- [ ] Filtres et recherche sur les listes
- [ ] Export CSV des factures
- [ ] Gestion des rôles (admin / member)
- [ ] Sidebar responsive / collapsible sur mobile
- [ ] Numérotation automatique des factures
- [ ] Mentions légales sur le PDF (CGV, conditions de paiement)

## Licence

Projet privé — Facturini
