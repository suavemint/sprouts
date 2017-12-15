class CreateTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :transactions do |t|
      t.string :transaction_url
      t.float :amount
      t.string :status

      t.timestamps
    end
  end
end
