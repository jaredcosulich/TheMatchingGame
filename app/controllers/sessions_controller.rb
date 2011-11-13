class SessionsController < ApplicationController

  def destroy
    @current_player = nil
    if session = UserSession.find
      session.destroy
    end
    clear_cookies
    redirect_to root_path
  end

  def show
    redirect_to new_session_path
  end

  def new
    @session = UserSession.new
    unless @current_player.user
      @current_player.user = User.new
      @current_player.user.errors.clear
    end
    @hide_profile = true
  end

  def create
    session
    login_params = params[:user_session]
    @session = UserSession.new(login_params)
    @session.save do |result|
      if result
        user = @session.record
        user.player.migrate_games_from(session['player_id'])
        @current_player = user.player
        redirect_to_after_login(account_path)
      else
        @user = User.new(:email => params[:user_session][:email])
        @hide_profile = true
        render :action => :new
      end
    end

  end
  def log_all_requests?
    true
  end
end
