# Facturini

Application SaaS B2B de facturation multi-tenancy construite avec Ruby on Rails 8. MVP fonctionnel avec authentification, gestion de clients et factures, workflow de statuts complet, calculs automatiques, génération PDF et un design system cohérent.

## Stack technique

| Catégorie | Technologie |
|-----------|-------------|
| **Framework** | Ruby on Rails 8.1 |
| **Ruby** | 3.3.4 |
| **Base de données** | PostgreSQL |
| **CSS** | Tailwind CSS |
| **Icônes** | Heroicons (SVG inline) |
| **Email** | ActionMailer + Brevo SMTP |
| **Password Reset** | Token-based reset flow |
| **Authentification** | `has_secure_password` + sessions |
| **PDF** | Prawn + prawn-table |
| **Tests** | RSpec, FactoryBot, Shoulda Matchers |
| **i18n** | Rails I18n (locale `fr`) |

## Architecture

### Principes appliqués

- **Service Objects** — Logique métier isolée dans `app/services/` (`InvoiceCalculator`, `InvoicePdfGenerator`)
- **Thin Controllers** — Les contrôleurs délèguent aux méthodes métier du modèle (`editable?`, `finalizable?`, etc.)
- **Multi-tenancy** — Toutes les données scopées par `Organization`, aucun accès cross-tenant possible
- **RESTful** — Routes `resources` standard Rails + routes `member` pour les transitions de workflow
- **Business Logic in Model** — Méthodes de workflow centralisées sur `Invoice` (`editable?`, `finalizable?`, `sendable?`, `cancellable?`, `payable?`, `downloadable?`)
- **DRY Helpers** — Badges de statut centralisés dans `IconsHelper` (`invoice_status_badge_class`, `invoice_status_label`)
- **DRY Layouts** — Trois layouts distincts (`application`, `auth`, `landing`)
- **Responsive Design** — Mobile-first avec menu burger et sidebar adaptable
- **Branding** — Couleurs personnalisées Tailwind (`#0A3966`, `#27AE60`)
- **DRY Footer** — Composant partagé avec liens légaux et réseaux sociaux

### Structure du projet

```
app/
├── controllers/
│   ├── concerns/
│   │   └── authentication.rb       # Module session/current_user/require_auth
│   ├── application_controller.rb   # Inclut Authentication
│   ├── sessions_controller.rb      # Login/Logout (layout: auth)
│   ├── registrations_controller.rb # Inscription org + user (layout: auth)
│   ├── dashboard_controller.rb     # Tableau de bord
│   ├── clients_controller.rb       # CRUD Clients
│   ├── invoices_controller.rb      # CRUD + workflow (finalize, send, cancel, mark_as_paid, download_pdf)
│   └── invoice_items_controller.rb # Ajout/suppression de lignes
├── models/
│   ├── organization.rb             # Tenant principal, invoice_prefix
│   ├── user.rb                     # has_secure_password, enum role
│   ├── client.rb                   # enum client_type
│   ├── invoice.rb                  # enum status (5 états), workflow methods, numéro auto
│   └── invoice_item.rb             # Lignes de facture
├── services/
│   ├── invoice_calculator.rb       # Calcul HT, TVA, TTC en centimes
│   └── invoice_pdf_generator.rb    # Génération PDF avec Prawn
├── helpers/
│   └── icons_helper.rb             # Heroicons SVG inline + badge helpers statut
├── views/
│   ├── layouts/
│   │   ├── application.html.erb    # Layout principal (sidebar + content)
│   │   ├── auth.html.erb           # Layout authentification (centré)
│   │   ├── landing.html.erb        # Layout landing page (full width)
│   │   └── _footer.html.erb        # Composant footer partagé
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
- **Inscription** — Création simultanée d'une `Organization` et d'un `User` (owner) dans une transaction atomique
- **Login/Logout** — Authentification par email/mot de passe avec session cookie
- **Protection** — `before_action :require_authentication` sur tous les controllers sauf auth
- **Erreurs explicites** — Les erreurs de validation sont affichées directement dans le formulaire (en français)
- **Layout dédié** — Pages auth avec layout centré (`auth.html.erb`), sans sidebar
- **Logo cliquable** — Redirection vers la home page depuis le login
- **Couleurs de marque** — Boutons et focus utilisant les couleurs `#0A3966` et `#27AE60`

### Organisations
- Création lors de l'inscription avec les informations légales (SIRET, SIREN, TVA, capital, forme juridique)
- **Préfixe de facturation** (`invoice_prefix`) — 3 lettres majuscules (ex: `FAC`, `INV`), défini à l'inscription, utilisé pour la numérotation automatique des factures

### Clients (CRUD complet)
- Création, lecture, modification, suppression
- Champs : nom, email, téléphone, adresse, ville, code postal, pays, SIRET
- Types : **Particulier** / **Professionnel** (enum `client_type`)
- Scoped à l'organization de l'utilisateur connecté

### Factures — Workflow à 5 statuts

```
draft ──► finalized ──► sent ──► paid
              │
              └──► cancelled
```

| Statut | Label | Couleur | Actions disponibles |
|--------|-------|---------|---------------------|
| `draft` | Brouillon | Gris | Modifier, Finaliser, Supprimer |
| `finalized` | Finalisée | Indigo | Envoyer, Annuler, PDF |
| `sent` | Envoyée | Vert | Marquer payée, PDF |
| `paid` | Payée | Violet | PDF |
| `cancelled` | Annulée | Rouge | — |

**Règles métier (méthodes sur `Invoice`)** :
- `editable?` — `draft?` uniquement
- `finalizable?` — `draft?` + au moins une ligne + `due_date` présente
- `sendable?` — `finalized?` uniquement
- `cancellable?` — `finalized?` uniquement
- `payable?` — `sent?` uniquement
- `downloadable?` — `finalized?`, `sent?` ou `paid?`

**Numérotation automatique** — Le numéro est généré à la création via `before_create :set_invoice_number` au format `{PREFIX}-{SEQ}` (ex: `FAC-001`, `FAC-002`). La séquence est isolée par organisation. Le champ n'est pas saisissable par l'utilisateur.

### Lignes de facture
- Ajout/suppression dynamique depuis la page show de la facture (uniquement en `draft`)
- Champs : description, quantité, prix unitaire (en centimes), taux de TVA (%)
- **Recalcul automatique** des totaux à chaque ajout/suppression via `InvoiceCalculator`

### Calculs automatiques (`InvoiceCalculator`)
- **Total HT** = Σ (quantité × prix unitaire) par ligne
- **TVA** = Σ (total_ligne × taux_tva / 100) par ligne
- **Total TTC** = HT + TVA
- Stockage en **centimes (integer)** pour éviter les erreurs d'arrondi float

### Génération PDF (`InvoicePdfGenerator`)
- Génération avec Prawn + prawn-table
- Disponible uniquement à partir du statut `finalized`
- Contenu : informations organization, client, détails facture, tableau des lignes, totaux
- Téléchargement via `send_data` au format `facture_{numero}.pdf`

### Dashboard
- Compteurs : nombre de factures et de clients
- Liens rapides vers les listes
- Textes et compteurs responsive (mobile/desktop)

### Landing Page
- **Page d'accueil publique** avec logo, slogan, CTA vers connexion
- **Section features** présentant les avantages (factures, clients, responsive)
- **Footer pro** avec liens légaux et réseaux sociaux
- **Logo complet** sur la landing, **logo texte-only** dans l'app

### Pages Légales
- **CGV** (`/cgv`) — Conditions Générales de Vente
- **Confidentialité** (`/confidentialite`) — Politique de confidentialité RGPD
- **Mentions légales** (`/mentions-legales`) — Informations éditeur/hébergement

## Design System

### Layouts
- **`application.html.erb`** — Sidebar fixe (256px) + zone de contenu principale
- **`auth.html.erb`** — Layout centré, fond `gray-50`, max-width 448px
- **`landing.html.erb`** — Layout pleine largeur pour landing page

### Composants visuels

| Composant | Classes Tailwind |
|-----------|-----------------|
| **Card** | `bg-white shadow-sm rounded-xl border border-gray-200` |
| **Input** | `border-gray-300 rounded-lg shadow-sm text-sm focus:ring-2 focus:ring-indigo-500` |
| **Bouton principal** | `bg-indigo-600 rounded-lg text-sm font-medium hover:bg-indigo-700 transition` |
| **Bouton succès** | `bg-green-600 text-white rounded-lg hover:bg-green-700 transition` |
| **Bouton danger** | `bg-red-50 text-red-600 rounded-lg hover:bg-red-100` |
| **Bouton secondaire** | `bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200` |
| **Badge draft** | `bg-gray-100 text-gray-700` |
| **Badge finalized** | `bg-primary/10 text-primary` |
| **Couleur primary** | `#0A3966` (bleu marine) |
| **Couleur accent** | `#27AE60` (vert) |
| **Badge sent** | `bg-green-100 text-green-700` |
| **Badge paid** | `bg-violet-100 text-violet-700` |
| **Badge cancelled** | `bg-red-100 text-red-700` |
| **Erreurs** | `bg-red-50 border-red-200 text-red-700 rounded-lg text-sm` |

### Icônes (Heroicons)
SVG inline via `IconsHelper` — usage : `<%= icon("eye", css_class: "size-4") %>`

| Icône | Utilisation |
|-------|------------|
| `chart-bar` | Sidebar — Tableau de bord |
| `document-text` | Sidebar — Factures |
| `users` | Sidebar — Clients |
| `arrow-right-on-rectangle` | Sidebar — Déconnexion |
| `eye` | Listes — Voir |
| `pencil-square` | Modifier |
| `trash` | Supprimer |
| `check-circle` | Finaliser une facture |
| `paper-airplane` | Envoyer une facture |
| `banknotes` | Marquer comme payée |
| `x-mark` | Annuler / Supprimer une ligne |
| `arrow-down-tray` | Télécharger PDF |
| `exclamation-triangle` | Avertissement (ex: due_date manquante) |
| `arrow-left` | Retour |

## Modèles & Relations

```
Organization
├── invoice_prefix (string, 3 lettres majuscules, default: "FAC")
├── has_many :users
├── has_many :clients
└── has_many :invoices

User (belongs_to :organization)
├── has_secure_password
└── enum role: { member: 0, owner: 1 }

Client (belongs_to :organization)
└── enum client_type: { individual: 0, professional: 1 }

Invoice (belongs_to :organization, :client)
├── has_many :invoice_items (dependent: :destroy)
├── enum status: { draft: 0, finalized: 1, sent: 2, paid: 3, cancelled: 4 }
├── number (généré automatiquement via before_create)
├── finalized_at, sent_at (timestamps de transition)
└── Totaux calculés par InvoiceCalculator (en centimes)

InvoiceItem (belongs_to :invoice)
└── description, quantity, unit_price_cents, vat_rate
```

## Routes

```ruby
# Auth
GET/POST   /login        → sessions#new/create
DELETE     /logout       → sessions#destroy
GET/POST   /signup       → registrations#new/create

# App
GET        /             → redirect vers /dashboard
GET        /dashboard    → dashboard#index

# CRUD
resources :clients

resources :invoices do
  resources :invoice_items, only: [:create, :destroy]
  member do
    patch :finalize_invoice   # draft      → finalized
    patch :send_invoice       # finalized  → sent
    patch :cancel_invoice     # finalized  → cancelled
    patch :mark_as_paid       # sent       → paid
    get   :download_pdf       # finalized | sent | paid
  end
end
```

## Sécurité

### Authentification
- `has_secure_password` (bcrypt) pour le hashing des mots de passe
- Session cookie httponly pour maintenir la connexion
- `before_action :require_authentication` sur tous les controllers (sauf auth)
- Token CSRF sur tous les formulaires
- `autocomplete="off"` sur tous les formulaires

### Multi-tenancy
Toutes les requêtes sont scopées à l'organization de l'utilisateur connecté :
```ruby
current_user.organization.invoices.find(params[:id])
current_user.organization.clients.find(params[:id])
```
Aucune donnée d'une autre organization n'est accessible, même en manipulant les IDs.

### Workflow des factures
Les transitions sont protégées au niveau du contrôleur **et** du modèle. Une facture non éditable bloque :
- Toute modification via `update`
- L'ajout/suppression de lignes via `InvoiceItemsController`
- La suppression via `destroy`
- Les transitions invalides (ex: `sent` → `finalize`, `draft` → `send`)

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

# Avec documentation détaillée
bundle exec rspec --format documentation
```

### Couverture des tests

| Catégorie | Fichier | Ce qui est testé |
|-----------|---------|-----------------|
| **Model specs** | `spec/models/invoice_spec.rb` | Validations, workflow methods, génération numéro auto |
| **Model specs** | `spec/models/organization_spec.rb` | Validations, unicité, associations |
| **Request specs** | `spec/requests/authentication_spec.rb` | Login, logout, inscription, protection des pages |
| **Request specs** | `spec/requests/clients_spec.rb` | CRUD clients, validations, scoping |
| **Request specs** | `spec/requests/invoices_spec.rb` | CRUD, workflow complet (finalize/send/cancel/pay/pdf), restrictions |
| **Request specs** | `spec/requests/invoice_items_spec.rb` | Ajout/suppression lignes, recalcul totaux |
| **Service specs** | `spec/services/invoice_calculator_spec.rb` | Calculs HT, TVA, TTC, cas limites |
| **Service specs** | `spec/services/invoice_pdf_generator_spec.rb` | Génération binaire PDF valide |

## Roadmap

- [x] **Landing page** avec présentation SaaS et footer pro
- [x] **Logo et branding** — Couleurs personnalisées, favicon, logos SVG
- [x] **Responsive design** — Menu mobile burger, textes adaptatifs
- [x] **Pages légales** — CGV, Confidentialité, Mentions légales
- [x] **Password reset** — Email + token sécurisé
- [ ] Page de paramètres organisation (modifier préfixe, informations légales)
- [ ] Filtres et tri sur la liste des factures (par statut, date, client)
- [ ] Dashboard avancé (CA mensuel, factures impayées, graphiques)
- [ ] Envoi de factures par email (ActionMailer + PJ PDF)
- [ ] Pagination des listes (Pagy)
- [ ] Export CSV des factures
- [ ] Gestion des rôles (admin / member)
- [ ] Ajout rapide de client depuis le formulaire de facture (modal Turbo)
- [ ] Mentions légales sur le PDF (CGV, conditions de paiement)

## Déploiement

L'app est déployée sur un VPS Scaleway via **Kamal** (outil de déploiement officiel Rails 8).

### Infrastructure

| Élément | Valeur |
|---------|--------|
| **Serveur** | VPS Scaleway — `51.15.98.213` |
| **Domaine** | https://facturini.fr |
| **Proxy** | kamal-proxy (SSL automatique via Let's Encrypt) |
| **Base de données** | PostgreSQL 17 (container Docker) |
| **Registry Docker** | Docker Hub — `ayoubsourrakh/facturini` |

### Prérequis

- Docker installé sur ta machine locale
- Kamal installé (`gem install kamal`)
- Accès SSH au serveur (`ssh root@51.15.98.213`)
- Compte Docker Hub

### Fichier des secrets

Créer `.kamal/secrets` (jamais commité) :

```bash
RAILS_MASTER_KEY=$(cat config/master.key)
KAMAL_REGISTRY_PASSWORD=ton_mot_de_passe_docker_hub
POSTGRES_PASSWORD=ton_mot_de_passe_postgres
```

### Premier déploiement

```bash
kamal setup    # Configure le serveur + démarre kamal-proxy
kamal deploy   # Build l'image, la push sur Docker Hub, démarre les containers
```

### Déploiements suivants

```bash
kamal deploy
```

### Commandes utiles

```bash
kamal app logs -f                  # Logs en temps réel
kamal app exec --interactive --reuse "bin/rails console"  # Console Rails
kamal app exec --interactive --reuse "bash"               # Shell dans le container
kamal app restart                  # Redémarrer sans redéployer
```

### Points importants

**Variables d'environnement** — L'app attend :
- `RAILS_MASTER_KEY` — clé pour déchiffrer les credentials
- `POSTGRES_PASSWORD` — mot de passe PostgreSQL (aussi utilisé par le container db)
- `DB_HOST` — nom du container PostgreSQL (`facturini-db`)

**Solid Queue désactivé** — `SOLID_QUEUE_IN_PUMA=false` dans `deploy.yml`. Le queue adapter est `:async` (jobs en mémoire). Voir `NOTES_DEPLOY.md` pour réactiver la solid trifecta.

**Bug connu résolu** — Dans `config/puma.rb`, la condition est `== "true"` (string explicite) et non juste `if ENV[...]` car en Ruby une string `"false"` est truthy et lancerait solid_queue même désactivé.

## Licence

Projet privé — Facturini
