class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.text :address
      t.string :city
      t.string :zip_code
      t.string :country, default: "FR"
      t.string :siret
      t.string :vat_number
      t.integer :client_type, default: 1, null: false

      t.timestamps
    end

    add_index :clients, [:organization_id, :email]
    add_index :clients, [:organization_id, :name]
  end
end