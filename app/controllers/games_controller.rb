class GamesController < ApplicationController

  def index
    redirect_to root_path and return if @current_player.games.empty?
    @answers = @current_player.answers.full.find(:all, :conditions => ["game_id = ?",@current_player.games.last], :limit => 100)
  end

  def create
    game = Game.create(:player => @current_player)
    respond_to do |format|
      format.html { redirect_to game_path(game) }
      format.json do
        if params[:location]
          location_attrs = {:geo_lat => params[:location][:latitude], :geo_lng => params[:location][:longitude]}
          unless params[:location][:address].blank?
            address = params[:location][:address]
            location_attrs[:geo_name] = "#{address[:city]}, #{address[:region]}, #{address[:country]}"
          end
          @current_player.update_attributes(location_attrs)
        end
        render :json => {:id => game.id}
      end
    end
  end

  def more_combos
    game = Game.find_by_id(params[:id]) unless params[:id] == "0"
    game = Game.new(:player => @current_player) if game.nil?
    if params.include?(:college)
      render :json => game.college_combos(20, params[:excluded_ids]).to_json
      return
    end
    render :json => game.combos(20, params[:excluded_ids]).to_json
  end

  def new
    render :json => Game.new(:player => Player.new).combos((params[:count] || Features.combos_to_show).to_i).to_json
  rescue => e
    render :json => {:error => e.class.name, :message => e.message}
  end

  def leaderboard
    @selected_tab = "leaderboard"
  end

end
