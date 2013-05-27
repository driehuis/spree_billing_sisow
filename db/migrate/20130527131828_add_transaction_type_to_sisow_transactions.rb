class AddTransactionTypeToSisowTransactions < ActiveRecord::Migration
  def change
    add_column :spree_sisow_transactions, :transaction_type, :string
  end
end
