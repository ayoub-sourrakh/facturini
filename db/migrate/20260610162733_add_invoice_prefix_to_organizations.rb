class AddInvoicePrefixToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :invoice_prefix, :string, default: "FAC", null: false
  end
end
