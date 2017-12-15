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

  private

  def allowed_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end
end
