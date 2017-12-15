class User < ApplicationRecord
  has_secure_password

  has_many :transactions

  def create_transaction! amount
    self.transactions << Transaction.new( amount: amount )
  end
end
