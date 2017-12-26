class CreateAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :accounts do |t|
      t.string :account_id
      t.boolean :needs_verification, default: true
      t.boolean :has_verified, default: false
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
