# Facturini

Application SaaS B2B de facturation multi-tenancy construite avec Ruby on Rails 8.

## Stack Technique

- **Framework** : Ruby on Rails 8.0
- **Ruby** : 3.3.4
- **Database** : PostgreSQL
- **CSS** : Tailwind CSS
- **Authentification** : `has_secure_password` + sessions
- **PDF** : Prawn
- **Testing** : RSpec, FactoryBot, Shoulda Matchers

## Architecture

### Principes appliqués

- **Service Objects** : Logique métier isolée (`InvoiceCalculator`, `InvoicePdfGenerator`)
- **Thin Controllers** : Les contrôleurs gèrent uniquement HTTP/routing
- **Multi-tenancy** : Scoping par `Organization` sur tous les modèles
- **RESTful** : Routes resources standard Rails
- **Sécurité** : Authentification requise, accès scoped à l'organization

### Structure des dossiers

```
app/
├── controllers/          # Gestion HTTP, params, flash, redirections
├── models/              # Données, validations, associations
├── services/            # Logique métier (calculs, PDF)
├── views/               # Présentation (ERB + Tailwind)
└── concerns/            # Modules réutilisables (Authentication)
```

## Fonctionnalités MVP

### Authentification
- Inscription (Organization + Owner User)
- Login/Logout avec sessions
- Protection des pages

### Clients
- CRUD complet (nom, email, adresse, SIRET, etc.)
- Types : Particulier / Professionnel

### Factures
- CRUD avec workflow de statuts :
  - `draft` (brouillon) : Modifiable, supprimable
  - `sent` (envoyée) : Lecture seule, date d'envoi enregistrée
- Numéro unique par organization
- Dates d'émission et d'échéance
- Objet/description

### Lignes de facture (InvoiceItems)
- Ajout/suppression dynamique
- Description, quantité, prix unitaire (centimes), taux de TVA
- **Recalcul automatique** des totaux via `InvoiceCalculator`

### Calculs automatiques
- Total HT (subtotal)
- Montant TVA
- Total TTC
- Stockage en centimes (integer) pour éviter les erreurs de float

### PDF
- Génération inline avec Prawn
- Tableau des lignes avec totaux
- Téléchargement depuis la page facture

## Installation

```bash
# Cloner le repo
git clone [url]
cd facturini

# Installer les dépendances
bundle install

# Setup base de données
rails db:create db:migrate

# Lancer le serveur
bin/dev
```

## Tests

```bash
# Tous les tests
bundle exec rspec

# Tests avec couverture
bundle exec rspec --format documentation
```

**Résultat actuel** : 79 tests, 0 failures

## Modèles & Relations

```
Organization
├── has_many :users
├── has_many :clients
└── has_many :invoices

Invoice (belongs_to :organization, :client)
├── has_many :invoice_items
├── enum status: { draft: 0, sent: 1, paid: 2 }
└── Calculs via InvoiceCalculator

Client (belongs_to :organization)
└── enum client_type: { individual: 0, professional: 1 }

User (belongs_to :organization)
└── enum role: { member: 0, admin: 1 }
```

## Sécurité & Workflow

### Protection des factures finalisées
Une facture marquée comme "envoyée" devient **en lecture seule** :
- Impossible de modifier (édition bloquée)
- Impossible d'ajouter/supprimer des lignes
- Impossible de supprimer la facture
- PDF téléchargeable uniquement

### Multi-tenancy
Toutes les requêtes sont scopées à l'organization de l'utilisateur connecté :
```ruby
current_user.organization.invoices.find(params[:id])
```

## Roadmap future

- [ ] Envoi de factures par email (avec PJ PDF)
- [ ] Statut "Payée" avec date de paiement
- [ ] Tableau de bord avec stats (CA, impayés)
- [ ] Design system pro (composants UI)
- [ ] Pagination des listes
- [ ] Filtres et recherche

## License

Projet privé - Facturini
