class ProfilesController < ApplicationController
  before_filter :ensure_registered_user, :only => [:edit, :update]

  def show
    redirect_to account_path  
  end

  def edit
    @current_player.build_profile unless @current_player.profile
  end

  def update
    @current_player.update_attributes(params[:player])
    @current_player.update_attributes(:preferred_profile => params[:preferred_profile] == "facebook" ? @current_player.facebook_profile : @current_player.profile)
    @current_player.update_interests(params[:interests])
    flash[:notice] = "Profile Changes Saved Successfully."
    redirect_to account_path
  end

  def facebook
    uid = params[:fb_info][:uid] || params[:fb_info][:id] rescue nil
    render :nothing => true and return if uid.blank?
    
    user = User.find_or_create_fb(@current_player.id, uid)
    @current_player = user.player

    result = @current_player.update_from_facebook(params[:fb_info])
    render :json => {:player_id => @current_player.id, :result => result}
  end

  def log_all_requests?
    true
  end
end
