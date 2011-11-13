class PrioritiesController < ApplicationController
  before_filter :ensure_registered_user
  before_filter :set_tab

  def index
    @priority = Priority.new
    @photos = @current_player.photos.approved_or_confirmed.where("couple_combo_id is null")
    @selected_subtab = "apply"
  end

  def create
    if @current_player.user.credits >= params[:priority][:credits_to_apply].to_i
      Priority.create(params[:priority])
    else
      flash[:notice] = "You don't have enough credits to do that."
    end
    redirect_to priorities_path
  end

  private
  def set_tab
    @selected_tab = "priorities"
  end

end
