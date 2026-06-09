class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.text :address
      t.string :city
      t.string :zip_code
      t.string :country, default: "FR"
      t.string :siren
      t.string :siret
      t.string :vat_number
      t.string :legal_form
      t.decimal :capital, precision: 15, scale: 2
      t.string :logo

      t.timestamps
    end

    add_index :organizations, :email, unique: true
    add_index :organizations, :siret, unique: true
    add_index :organizations, :vat_number, unique: true
  end
end
