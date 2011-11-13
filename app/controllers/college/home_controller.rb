class College::HomeController < ApplicationController
  before_filter :register_from_facebook
  layout "college"

  def index
    @game = @current_player.games.last
    @game = Game.create(:player => @current_player) if @game.nil?
    @combos = @game.college_combos(11)
    @badges = @current_player.badges
    @selected_tab = "play"
  end

  def not_ready
    @selected_tab = "get_matched"
  end

  def frame
    render :layout => false
  end

  def register_from_facebook
    if @current_player.nil? || @current_player.college_id.nil?
      if params.include?(:code)
        access_token = FacebookProfile.get_access_token(params[:code])
        session["access_token"] = access_token
        session["access_token"]
        user = FacebookProfile.find_or_create_college_user(access_token)
        @current_player = user.player
        UserSession.create(user)
      end
    end    
  end
end
