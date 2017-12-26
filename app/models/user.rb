class User < ApplicationRecord
  has_secure_password

  has_many :transactions
  has_many :accounts
=begin
  def self.dwolla
    @d ||= DwollaV2::Client.new(key: 'RSiQHK9g6X0y2sFQ3fzlqZKRYYnARHL3xDtKbY6Kwf4KMAnu6R', secret: 'Ro5Wyhq9cxxqtjfHTpzIGih0nViVNNBU7wtn6rOaFadvby7pTa') {|cfg| cfg.environment = :sandbox }
  end

  def self.application_token
    @appt ||= self.dwolla.auths.client
  end

  def self.access_token
    puts "TESTING ACCESS TOKEN: #{self.application_token.access_token}"
    @accesst ||= self.application_token.access_token
  end

  def self.account_token
    puts "TESTING ACCOUNT TOKEN: #{self.dwolla.tokens.new access_token: self.access_token}"
    @at ||= self.dwolla.tokens.new access_token: self.access_token
  end

  def self.account_url
    @acct_url ||= self.account_token.get('/')[:_links][:account][:href]
    puts "ACCOUNT URL RETRIEVED? #{@acct_url}"
    @acct_url
  end

  def self.create_customer first_name, last_name, email
    # Step 1: check if customer exists on server. If not, create it on server, and save to DB.
    # Step 2: check if funding source exists on customer on server. If not, it will be created on-page.
    # Step 3: save to database, including customer_url
    puts "User#create_customer called"

    customer_obj = { first_name: first_name, last_name: last_name, email: email }
    customer = self.create_customer_on_server customer_obj
    customer_url = customer[:_links][:self][:href]
    User.new first_name: first_name, 
      last_name: last_name, 
      email: email, 
      customer_url: customer_url
  end

  # TODO delete this method? Need one customer at a time, really
  def self.customers
    self.account_token.get('customers')._embedded.customers
    #self.account_token.get('customers')._embedded.customers.map do |customer|
    #  self.extract_customer customer
    #end
  end

  # Retrieve list of known customers to application, and return boolean if given object is in that array.
  #def self.customer_exists_on_server? customer
  #  self.customers.select {|c|
  #    c.first_name == customer.first_name and c.last_name == customer.last_name and c.email == customer.email
  #  }.length == 1
  #end

  def self.get_customer_from_server customer
    customer_test = self.customers.select {|c|
      c.email == customer.email  # FIXME add more criteria? 
    }.first

    puts "CUSTOMER ALREADY EXISTS ON SERVER? #{customer_test}"
    if customer_test.nil?
      puts "CUSTOMER DOES NOT EXIST. CREATING..."
      customer_test = self.create_customer_on_server( customer )
    end
    customer_test.customer_url = customer_test[:_links][:self][:href]
    customer_test
  end

  def self.get_funding_source_from_customer customer
    customer_from_server = self.get_customer_from_server( customer )
    customer_from_server[:_links][:"funding-sources"]
  end

  def self.create_customer_on_server customer
    #unless self.get_customer_from_server customer
    puts "#create_customer_on_server speaking.. customer does not exist yet on server #{customer}"
      request_body = {
        firstName: customer.first_name,
        lastName:  customer.last_name,
        email:     customer.email,
        ipAddress: '192.168.1.1'
      }
      new_customer = self.account_token.post 'customers', request_body
      customer.customer_url = new_customer.response_header[:location]
      puts "-> now, does Customer URL retrieved for customer obj = #{customer}: #{customer.customer_url}"
    #else
    #end
    #customer.customer_url
  end

  def self.create_funding_source_on_customer customer
    unless self.get_funding_source_from_customer( customer)
      puts "Funding source NOT FOUND on customer object #{customer}..."
      # Use customer url to create funding source on that customer entry/object.
      customer_url = customer[:_links][:self][:href]
    end
  end

  # Convenience extractor method
  #def self.extract_customer customer
  #  { first_name: customer.firstName, last_name: customer.lastName, email: customer.email }
  #end
  #

  def self.transactions
  end

  def create_transaction! amount
    #self.transactions << Transaction.new( amount: amount )
  end

  # Instance methods
  def full_name
    [first_name, last_name].join ' '
  end

  # Method that should be private, but needs to be used when there's an error with the IAV token.

  def token
    puts "Going to get token value for user #{self}"
    c_url = User.get_customer_from_server(self).customer_url 
    c = User.account_token.post("#{c_url}/iav-token")
    puts "C TOKEN???? #{c.token}"
    #@t ||= c.token
    @t = c.token
    puts "Customer token retrieved? #{@t}"
    @t
  end
=end
end
