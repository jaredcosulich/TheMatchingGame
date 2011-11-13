class MatchMeController < ApplicationController
  before_filter :load_target_photo, :except => [:index]
  before_filter :set_tab

  def index
    @photo = @current_player.photos.first
    redirect_to new_photo_path and return if @photo.nil?
  end

  def show
    if @target_photo.player != @current_player
      referrer = Referrer.find_by_uid("match_me")
      Referral.create!(:referrer => referrer, :player => @current_player)
    end
  end

  def play
    @game = Game.create(:player => @current_player)
    @combos = MatchMeGame.new(@target_photo, @current_player, @game).combos(10)
  end

  def friends
    @page = (params[:page] || 0).to_i
    @friend_suggestions = MatchMeAnswer.friend_suggestions(@target_photo, 12, @page)
  end

  private
  def load_target_photo
    @target_photo = Photo.find(Integer.unobfuscate(params[:id]))
  end

  def set_tab
    @selected_tab = "friends"
  end

end
