class UsersController < ApplicationController
  protect_from_forgery only: [:create, :new, :show]  # TODO use except + handle instead?
  #protect_from_forgery except: [ :handle_plaid, :handle_funding_source ]

  def new
    @user = User.new
  end

  def create
    @user = User.new allowed_params
    if @user.save
      redirect_to @user, notice: "Thanks for signing up!"
    else
      render :new
    end
  end

  def show
    @user = User.find params[:id]
  end

  # Endpoint for handling response from the Plaid Link JS API in the client.
  # FIXME save plaid_public_token to different field/DB??
  def handle_plaid
    puts "#handle_plaid called given params #{params}"
    user = User.find params[:user_id]
    user.plaid_public_token = params[:plaid_public_token]
    user.save
    puts "#handle_plaid done; user token value saved to DB"
    puts "TESTING AMOUNT RETRIEVAL AT ENDPOINT: #{params[:amount]}"

    # Stripe acepts charge amounts as an integer, in units of cents...
    puts "Before int-ization, amount = #{params[:amount]}"
    amount = params[:amount].to_i * 100
    puts "After int-ization, amount = #{amount}"
    # FIXME
    # Using Plaid:
    plaid_client = Plaid::Client.new env:        :sandbox,
                                     client_id:  '5a399ded8d92397ccb899be3',
                                     secret:     'a45f9991f66f776fb519e218feb7b7',
                                     public_key: '62878a3db427049cad3d889547f2d7'

    # With a plaid public token for an access token -and- a sripe bank acct token
    exchange_token_response = plaid_client.item.public_token.exchange( user.plaid_public_token )
    puts "DEBUG PLAID EXCH TOKEN RESPONSE: #{exchange_token_response}"
    access_token = exchange_token_response['access_token']
    puts "DEBUG PLAID ACCESS TOKEN: #{access_token}"
#byebug
    # FIXME need account id from 
    stripe_response = plaid_client.processor.stripe.bank_account_token.create( access_token, params[:plaid_account_id] )
    #stripe_response = plaid_client.processor.stripe.bank_account_token.create( access_token, bank_account_id )
    #stripe_response = plaid_client.processor.stripe.bank_account_token.create( access_token, exchange_token_response['item_id'])
    puts "DEBUG STRIPE RESPONSE: #{stripe_response}"

    # FIXME add bank account token to DB record linked to user!!
    bank_account_token = stripe_response['stripe_bank_account_token']
    # TODO rename column account_id to bank_account_token
    bank_account = Account.find_or_create_by( user_id: user.id, account_id: bank_account_token )
    puts "DEBUG PLAID->STRIPE BANK ACCT TOKEN: #{bank_account_token}"

    # Create charge with bank account token from Stripe, sent by Plaid
    # A) prepare Stripe
    stripe_secret = 'sk_test_861hUPjcwi4xugctXZruPZEf'
    Stripe.api_key = stripe_secret
    charge = Stripe::Charge.create({ amount: amount, 
                                     currency: 'usd', 
                                     description: 'Sprouts Investments Deposit', 
                                     statement_descriptor: 'Sprouts Investments Dep',
                                     source: bank_account_token,
                                     metadata: {'customer_email': user.email } 
    })
    puts "What is charge/? #{charge}"

    # FIXME rename token column to transaction_id??
    transaction = Transaction.create user_id: user.id, 
                                     amount: params[:amount].to_i, 
                                     status: charge.status,
                                     token: charge.id, 
                                     balance_transaction: charge.balance_transaction, 
                                     charge_json: charge.to_json

    redirect_to user
  end

  # Example JSON request from a webhook event at Stripe:
  # "{
  # "created": 1326853478,
  # "livemode": false,
  # "id": "evt_00000000000000",
  # "type": "charge.pending",
  # "object": "event",
  # "request": null,
  # "pending_webhooks": 1,
  # "api_version": "2017-12-14",
  # "data": {
  #   "object": {
  #     "id": "ch_00000000000000",
  #     "object": "charge",
  #     "amount": 100,
  #     "amount_refunded": 0,
  #     "application": null,
  #     "application_fee": null,
  #     "balance_transaction": "txn_00000000000000",
  #     "captured": false,
  #     "created": 1513828561,
  #     "currency": "usd",
  #     "customer": null,
  #     "description": "My First Test Charge (created for API docs)",
  #     "destination": null,
  #     "dispute": null,
  #     "failure_code": null,
  #     "failure_message": null,
  #     "fraud_details": {
  #     },
  #     "invoice": null,
  #     "livemode": false,
  #     "metadata": {
  #     },
  #     "on_behalf_of": null,
  #     "order": null,
  #     "outcome": null,
  #     "paid": true,
  #     "receipt_email": null,
  #     "receipt_number": null,
  #     "refunded": false,
  #     "refunds": {
  #       "object": "list",
  #       "data": [

  #       ],
  #       "has_more": false,
  #       "total_count": 0,
  #       "url": "/v1/charges/ch_1BbLA5FGIyir0NXY5S1cBEbW/refunds"
  #     },
  #     "review": null,
  #     "shipping": null,
  #     "source": {
  #       "id": "card_00000000000000",
  #       "object": "card",
  #       "address_city": null,
  #       "address_country": null,
  #       "address_line1": null,
  #       "address_line1_check": null,
  #       "address_line2": null,
  #       "address_state": null,
  #       "address_zip": null,
  #       "address_zip_check": null,
  #       "brand": "Visa",
  #       "country": "US",
  #       "customer": null,
  #       "cvc_check": null,
  #       "dynamic_last4": null,
  #       "exp_month": 8,
  #       "exp_year": 2018,
  #       "fingerprint": "jGu58tISUN4fs5OE",
  #       "funding": "credit",
  #       "last4": "4242",
  #       "metadata": {
  #       },
  #       "name": null,
  #       "tokenization_method": null
  #     },
  #     "source_transfer": null,
  #     "statement_descriptor": null,
  #     "status": "succeeded",
  #     "transfer_group": null
  #   }
  # }
  #"
  def webhook
    puts "#webhook endpoint called."
    webhook_secret = ''
    json_response = JSON.parse params    

    webhook_type = json_response[:type]
    webhook_data = json_response[:data][:object]
    charge_id = webhook_data[:id]
    amount = webhook_data[:amount]
    description = webhook_data[:description]

    source = webhook_data[:source]
  end

=begin
  def handle_funding_source
    puts "#handle_funding_source called"
    stripe_key = 'pk_test_2YOIZqgQViMcqNpHxAjt1iSq'
    stripe_secret = 'sk_test_861hUPjcwi4xugctXZruPZEf'

    user = User.find params[:user_id]
    # Step 1: create customer
    # Step 2: create accont on customer if DNE
    # Step 3: create charge on account

    Stripe.api_key = stripe_secret

    #token_id = params[:token_id]
    stripe_public_token = params[:token_id]
    user.stripe_public_token = stripe_public_token 
    user.save

    amount = params[:amount]
    bank_account_id = params[:bank_account_id]

    # TODO remove some of these passed params?

    #puts "TESTING TOKEN ID PASS: #{token_id}"
    puts "TESTING TOKEN ID PASS: #{stripe_public_token}"
    puts "TESTING TOKEN ID ON USER RECORD: #{user.stripe_public_token}"
    puts "TESTING AMOUNT PASS: #{amount}"
    puts "TESTING ACCT ID PASS: #{bank_account_id}"

    # Using Plaid:
    plaid_client = Plaid::Client.new env:        :sandbox,
                                     client_id:  '5a399ded8d92397ccb899be3',
                                     secret:     'a45f9991f66f776fb519e218feb7b7',
                                     public_key: '62878a3db427049cad3d889547f2d7'

    # With a plaid public token for an access token -and- a sripe bank acct token
    exchange_token_response = plaid_client.item.public_token.exchange( user.plaid_public_token )
    puts "DEBUG PLAID EXCH TOKEN RESPONSE: #{exchange_token_response}"
    access_token = exchange_token_response['access_token']
    puts "DEBUG PLAID ACCESS TOKEN: #{access_token}"
#byebug
    # FIXME need account id from 
    stripe_response = plaid_client.processor.stripe.bank_account_token.create( access_token, bank_account_id )
    #stripe_response = plaid_client.processor.stripe.bank_account_token.create( access_token, exchange_token_response['item_id'])
    puts "DEBUG STRIPE RESPONSE: #{stripe_response}"

    # FIXME add bank account token to DB record linked to user!!
    bank_account_token = stripe_response['stripe_bank_account_token']
    puts "DEBUG PLAID->STRIPE BANK ACCT TOKEN: #{bank_account_token}"

    #customer = Stripe::Customer.create source: token_id, description: "Test 1"
    # Try to make a customer with a source id, for ACH
    #customer = Stripe::Customer.create source: token_id, description: "Test 1"
    # FIXME under construction
    customer = Stripe::Customer.create source: user.stripe_public_token, description: "Test 1"
    puts "TESTING CUSTOMER FROM STRIPE: #{customer}"
    bank_account = customer.sources.retrieve bank_account_id
    puts "TEStiNG ACCT FROM STRIPE: #{bank_account}"

    # Verify the bank account
    #bank_account.verify amounts: [32, 45] # TESTING ONLY, AMOUNTS ONLY!!!

    charge = Stripe::Charge.create amount: amount, currency: 'usd', customer: customer, description: "Test 1 charge 1 description"

    #token = Stripe::Source.create( {
    #  customer: '',
    #  original_source: '',
    #  usage: ''
    #}, 
    #{ stripe_account: '' } )

    # TODO commenting out Dwolla chunk, replacing with Stripe.
    #puts "Users#handle_funding_source called, with POST request from browser."
    #puts "Amount before decimlalization: #{params[:amount]}"
    #amount = params[:amount].include?('.') ? params[:amount] : params[:amount] + '.00'
    #amount = params[:amount].to_f
    #user_id = params[:user_id]

    #(1..2000).each do |amt|
      #amount = params[:amount]
    #  puts "Amount after decimlalization: #{amount}"

    #  transfer_request_body = {
    #    _links: {
    #      source: {
    #        href: params[:funding_source_url]       
    #      },
    #      destination: {
    #        href: User.account_url
    #      }
    #   },
    #   amount: {
    #     currency: 'USD',
         #value: amount
    #     value: amt.to_s + '.00'
    #   }
    # }
    #  puts "BEFORE SENDING TRANSFER Req, BODY IS: #{transfer_request_body}"
    #  begin
    #    retries ||= 0
    #    transfer     = User.account_token.post( 'transfers', transfer_request_body )
    #  rescue DwollaV2::ValidationError => e
    #    puts "TRIED VALUE = #{amt}..."
    #    puts "Dwolla error caught, will try again: #{e}"
    #    retry if (retries += 1) < 5
    #    puts "TRANSFER RESPONSE OBJ? #{transfer}"

    #    unless transfer.nil?
    #      transfer_url = transfer.response_headers[:location]
    #      puts "TRANSFER URL? " + transfer_url
    #    end

        # Create a transaction for the user, if the response is successful.
    #    Transaction.create user_id: user_id, amount: amount.to_f, status: ''
    #  end
=end
    #end

    # FIXME this feels hacky, creating an object just to redirect to a user...
    #user_id = params[:user_id].to_i
    #puts "TESTING USER ID BEFORE REDIRECT: #{user_id}"
    #redirect_to User.find( user_id )
  #end

  def handle_webhook
  end

  private

  def allowed_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end
end
