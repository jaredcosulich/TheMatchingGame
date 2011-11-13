class MapsController < ApplicationController
  before_filter :ensure_registered_user
  
  def show
    @player_location_info = Player.location_data(Gendery.opposite(@current_player.gender))
    @selected_tab = "labs"
    @selected_subtab = "map"
  end
end
