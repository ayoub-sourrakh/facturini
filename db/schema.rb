# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_10_162733) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "clients", force: :cascade do |t|
    t.text "address"
    t.string "city"
    t.integer "client_type", default: 1, null: false
    t.string "country", default: "FR"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.string "phone"
    t.string "siret"
    t.datetime "updated_at", null: false
    t.string "vat_number"
    t.string "zip_code"
    t.index ["organization_id", "email"], name: "index_clients_on_organization_id_and_email"
    t.index ["organization_id", "name"], name: "index_clients_on_organization_id_and_name"
    t.index ["organization_id"], name: "index_clients_on_organization_id"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.bigint "invoice_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0", null: false
    t.bigint "total_cents", default: 0, null: false
    t.bigint "unit_price_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.decimal "vat_rate", precision: 5, scale: 2, default: "20.0", null: false
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.date "due_date"
    t.datetime "finalized_at"
    t.date "issue_date", null: false
    t.text "notes"
    t.string "number", null: false
    t.bigint "organization_id", null: false
    t.text "payment_terms"
    t.datetime "sent_at"
    t.integer "status", default: 0, null: false
    t.string "subject"
    t.bigint "subtotal_cents", default: 0, null: false
    t.bigint "total_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "vat_amount_cents", default: 0, null: false
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["issue_date"], name: "index_invoices_on_issue_date"
    t.index ["organization_id", "number"], name: "index_invoices_on_organization_id_and_number", unique: true
    t.index ["organization_id"], name: "index_invoices_on_organization_id"
    t.index ["status"], name: "index_invoices_on_status"
  end

  create_table "organizations", force: :cascade do |t|
    t.text "address"
    t.decimal "capital", precision: 15, scale: 2
    t.string "city"
    t.string "country", default: "FR"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "invoice_prefix"
    t.string "legal_form"
    t.string "logo"
    t.string "name", null: false
    t.string "phone"
    t.string "siren"
    t.string "siret"
    t.datetime "updated_at", null: false
    t.string "vat_number"
    t.string "zip_code"
    t.index ["email"], name: "index_organizations_on_email", unique: true
    t.index ["siret"], name: "index_organizations_on_siret", unique: true
    t.index ["vat_number"], name: "index_organizations_on_vat_number", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.bigint "organization_id", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id", "email"], name: "index_users_on_organization_id_and_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
  end

  add_foreign_key "clients", "organizations"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoices", "clients"
  add_foreign_key "invoices", "organizations"
  add_foreign_key "users", "organizations"
end
