class AddPlaidPublicTokenAndStripePublicTokenToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :plaid_public_token, :string
    add_column :users, :stripe_public_token, :string
  end
end
