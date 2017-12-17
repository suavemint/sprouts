class UsersController < ApplicationController
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
    puts "Users#handle_funding_source called, with POST request from browser."
    puts "Amount before decimlalization: #{params[:amount]}"
    amount = params[:amount].include?('.') ? params[:amount] : params[:amount] + '.00'
    user_id = params[:user_id]

    #amount = params[:amount]
    puts "Amount after decimlalization: #{amount}"

    transfer_request_body = {
      _links: {
        source: {
          href: params[:funding_source_url]       
        },
        destination: {
          href: User.account_url
        }
     },
     amount: {
       currency: 'USD',
       value: amount
     }
   }
    puts "BEFORE SENDING TRANSFER Req, BODY IS: #{transfer_request_body}"
    begin
      retries ||= 0
      transfer     = User.account_token.post( 'transfers', transfer_request_body )
    rescue DwollaV2::ValidationError => e
      puts "Dwolla error caught, will try again: #{e}"
      retry if (retries += 1) < 2
      puts "TRANSFER RESPONSE OBJ? #{transfer}"
      transfer_url = transfer.response_headers[:location]
      puts "TRANSFER URL? " + transfer_url

      # Create a transaction for the user, if the response is successful.
      Transaction.create user_id: user_id, transaction_amount: amount.to_f, status: ''
    end

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
