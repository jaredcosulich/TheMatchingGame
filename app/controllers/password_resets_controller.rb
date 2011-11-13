class PasswordResetsController < ApplicationController
  def show
    redirect_to new_password_reset_path
  end

  def create
    user = User.find_by_email(params[:password_reset][:email])

    unless user
      flash[:notice] = "Email not found"
      redirect_to new_password_reset_path
      return
    end

    user.reset_perishable_token!
    flash[:notice] = "Please check your email at #{params[:password_reset][:email]}"
    Mailer.deliver_password_reset(user.email, edit_password_reset_url(:token => user.perishable_token))
    redirect_to new_session_path
  end

  def edit
    @token = params[:token]
    user = User.find_by_perishable_token(@token)
    unless user
      flash[:notice] = "Invalid Password Reset Request"
      redirect_to new_password_reset_path
    end    
  end

  def update
    user = User.find_by_perishable_token(params[:token])

    unless user
      flash[:notice] = "Invalid Password Reset Request"
      redirect_to new_password_reset_path
      return
    end

    result = user.update_attributes(params[:password_reset])
    if result
      flash[:notice] = 'Password Change Saved'
      @current_player = user.player
      redirect_to account_path
    else
      flash[:notice] = user.errors.full_messages.join(", ")
      @token = params[:password_reset][:token]
      render :action => :edit
    end
  end

  def log_all_requests?
    true
  end

end
