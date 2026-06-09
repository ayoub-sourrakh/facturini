class CreateInvoiceItems < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :description, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false, default: 1
      t.bigint :unit_price_cents, null: false, default: 0
      t.decimal :vat_rate, precision: 5, scale: 2, null: false, default: 20.0
      t.bigint :total_cents, null: false, default: 0

      t.timestamps
    end
  end
end
