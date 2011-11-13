class AccountsController < ApplicationController
  before_filter :ensure_registered_user, :only => [:edit, :update]

  def show
    redirect_to_after_login and return unless @current_player.user.nil?
    redirect_to leaderboard_games_path and return if @current_player.photos.empty?
  end

  def new
    redirect_to new_session_path
  end

  def edit
    @user = @current_player.user
    @current_player.user.build_email_preference if @current_player.user.email_preference.nil?
    @user.email = '' if @current_player.anonymous?
  end

  def create
    user_params = params[:player][:user_attributes].merge(:player => @current_player) rescue {}
    respond_to do |format|
      format.html do
        @current_player.user = User.new(user_params)
        unless @current_player.user.save
          @hide_profile = true
          render :action => :new
        else
          flash[:notice] = "You've registered successfully. Welcome to The Matching Game!"
          redirect_to_after_login(account_path)
        end
      end

      format.json do
        user = User.create(user_params.merge(:password => password = UUID.generate, :password_confirmation => password, :terms_of_service => true))
        profile = Profile.create(params[:player][:profile_attributes].merge(:player => @current_player))
        unless user.save && profile.save
          render :json => {:errorMessage => user.errors.full_messages.join(", ")}
        else
          render :json => {}
        end

      end
    end
  end

  def update
    result = @current_player.update_attributes(params[:player])
    if result
      if @current_player.reload.user.nil?
        @current_player.photos.each { |p| p.remove! rescue nil }
        @current_player = nil
        if session = UserSession.find
          session.destroy
        end
        clear_cookies
        flash[:notice] = "Your account has been deleted."
        redirect_to root_path
      else
        redirect_to_after_login(account_path)
      end
    else
      render :action => :edit
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to(account_path)
  end

  def help_response
    help_response = @current_player.help_response || @current_player.build_help_response
    help_response.update_attributes(params[:help_response])
    redirect_to case params[:help_response][:code]
      when "add_photo": new_photo_path
      when "share": new_share_path
      else account_path
    end
  end

  def log_all_requests?
    true
  end
  
end
