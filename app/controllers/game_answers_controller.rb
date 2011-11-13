class GameAnswersController < ApplicationController
  def create
    combo = Combo.find(params[:answer][:combo_id])
    render :nothing => true and return if combo.couple_combo? && combo.couple_complete?
    game = Game.find(params[:game_id])
    game.answers.create(params[:answer].merge(:player_id => @current_player.id))

    if @current_player.present? && params.include?(:badge)
      badge = Badge.find_by_icon(params[:badge])
      @current_player.player_badges.create(:badge_id => badge.id) unless badge.nil?
    end
    render :nothing => true
  end

  def show
    redirect_to games_path
  end
end
