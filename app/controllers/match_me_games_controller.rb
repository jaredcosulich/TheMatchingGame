class MatchMeGamesController < ApplicationController

  def show
    @target_photo = Photo.find(Integer.unobfuscate(params[:match_me_id]))
    match_query = MatchMeAnswer.where("player_id = ?", @current_player.id)
    @good_matches_count = match_query.where("answer = 'y'").count
    @bad_matches_count = match_query.where("answer = 'n'").count
    last_game_match = match_query.order("id desc").first
    redirect_to photo_path(@target_photo) and return if last_game_match.nil?
    last_game_match_query = match_query.where("game_id=?", last_game_match.game_id)
    @last_game_good_matches = last_game_match_query.where("answer = 'y'").all
    @last_game_bad_matches = last_game_match_query.where("answer = 'n'").all
    @answers = Game.find(last_game_match.game_id).answers
  end

  def answers
    match_me_params = params[:answer]
    match_me_params.merge!(:game_id => params[:id], :target_photo_id => params[:match_me_id], :player_id => @current_player.id)
    MatchMeAnswer.create(match_me_params)
    render :nothing => true
  end

end
