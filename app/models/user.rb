class User < ApplicationRecord
  has_secure_password

  has_many :transactions

  def self.dwolla
    @d ||= DwollaV2::Client.new(key: 'RSiQHK9g6X0y2sFQ3fzlqZKRYYnARHL3xDtKbY6Kwf4KMAnu6R', secret: 'Ro5Wyhq9cxxqtjfHTpzIGih0nViVNNBU7wtn6rOaFadvby7pTa') {|cfg| cfg.environment = :sandbox }
  end

  def self.application_token
    self.dwolla.auths.client
  end

  def self.access_token
    puts "TESTING ACCESS TOKEN: #{self.application_token.access_token}"
    self.application_token.access_token
  end

  def self.account_token
    puts "TESTING ACCOUNT TOKEN: #{self.dwolla.tokens.new access_token: self.access_token}"
    @at ||= self.dwolla.tokens.new access_token: self.access_token
  end

  def self.customers
    self.account_token.get('customers')._embedded.customers.map do |customer|
      self.extract_customer customer
    end
  end

  def self.extract_customer customer
    { first_name: customer.firstName, last_name: customer.lastName, email: customer.email }
  end

  def self.transactions
  end

  # FIXME make this a class method?
  def self.create_customer
    #self. 
  end

  def create_transaction! amount
    #self.transactions << Transaction.new( amount: amount )
  end
end
