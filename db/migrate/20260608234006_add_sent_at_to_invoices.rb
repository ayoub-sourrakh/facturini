class AddSentAtToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :sent_at, :datetime
  end
end
