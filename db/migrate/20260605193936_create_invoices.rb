class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :number, null: false
      t.date :issue_date, null: false
      t.date :due_date
      t.integer :status, default: 0, null: false
      t.string :subject
      t.bigint :subtotal_cents, default: 0, null: false
      t.bigint :vat_amount_cents, default: 0, null: false
      t.bigint :total_cents, default: 0, null: false
      t.string :currency, default: "EUR", null: false
      t.text :notes
      t.text :payment_terms
      t.datetime :finalized_at

      t.timestamps
    end

    add_index :invoices, [:organization_id, :number], unique: true
    add_index :invoices, :status
    add_index :invoices, :issue_date
  end
end