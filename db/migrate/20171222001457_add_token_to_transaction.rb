class AddTokenToTransaction < ActiveRecord::Migration[5.1]
  def change
    add_column :transactions, :token, :string
  end
end
