class UsersController < ApplicationController
  protect_from_forgery only: [:create, :new, :show]  # TODO use except + handle instead?

  def new
    @user = User.new
  end

  def create
    @user = User.new allowed_params
    if @user.save
      redirect_to root_url, notice: "Thanks for signing up!"
    else
      render :new
    end
  end

  def show
    @user = User.find params[:id]
  end

  def handle_funding_source
    stripe_key = 'pk_test_2YOIZqgQViMcqNpHxAjt1iSq'
    stripe_secret = 'sk_test_861hUPjcwi4xugctXZruPZEf'

    # Step 1: create customer
    # Step 2: create accont on customer if DNE
    # Step 3: create charge on account

    Stripe.api_key = stripe_secret

    token_id = params[:token_id]
    amount = params[:amount]
    bank_account_id = params[:bank_account_id]

    puts "TESTING TOKEN ID PASS: #{token_id}"
    puts "TESTING AMOUNT PASS: #{amount}"
    puts "TESTING ACCT ID PASS: #{bank_account_id}"

    # Using Plaid:
    plaid_client = Plaid::Client.new env:       :sandbox,
                                     client_id: '5a399ded8d92397ccb899be3',
                                     secret:    'a45f9991f66f776fb519e218feb7b7',
                                     public_key: '62878a3db427049cad3d889547f2d7'

    #customer = Stripe::Customer.create source: token_id, description: "Test 1"
    # Try to make a customer with a source id, for ACH
    customer = Stripe::Customer.create source: token_id, description: "Test 1"
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
    #end

    # FIXME this feels hacky, creating an object just to redirect to a user...
    redirect_to User.find( user_id )
  end

  def handle_webhook
  end

  private

  def allowed_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end
end
