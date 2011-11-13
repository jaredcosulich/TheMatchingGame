class PlayersController < ApplicationController
  before_filter :ensure_registered_user
  
  def update
    @current_player.update_attributes(params[:player])
    render :json => @current_player.as_json
  end

  def show
    @selected_tab = "matching"
    @highlighted_photo = Photo.find_by_id(Integer.unobfuscate(params[:id]), :include => {:player => [{:question_answers => :question}, :interests]})
    redirect_to player_path(Photo.random.first) if @highlighted_photo.nil?
  end

end
