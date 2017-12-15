class AddUserToTransactions < ActiveRecord::Migration[5.1]
  def up
    add_column :transactions, :user_id, :integer
  end

  def down
    remove_column :transaction, :user_id
  end
end
