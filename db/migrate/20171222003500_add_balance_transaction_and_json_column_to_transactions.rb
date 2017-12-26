class AddBalanceTransactionAndJsonColumnToTransactions < ActiveRecord::Migration[5.1]
  def change
    add_column :transactions, :balance_transaction, :string
    add_column :transactions, :charge_json, :json
  end
end
