class College::UsersController < ApplicationController
  layout "college"

  before_filter :set_tab

  def index
  end

  def update
    @current_player.update_attributes(:same_sex => params[:same_sex])
    photo = @current_player.college_photo
    photo.pause! if params[:pause] == "1" && photo.confirmed_or_approved?
    photo.resume! if params[:pause] == "0" && photo.paused_states?
    redirect_to college_users_path
  end

  protected
  def set_tab
    @selected_tab = "settings"
  end

end
