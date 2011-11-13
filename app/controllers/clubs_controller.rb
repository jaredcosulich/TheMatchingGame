class ClubsController < ApplicationController
  before_filter :ensure_registered_user
  before_filter :load_club, :except => [:index, :all, :popular]
  before_filter :set_tab

  def index
    @clubs = Club.popular.limit(6)
#    @trending = Club.trending(6)
    @random = Club.random.limit(12)
    @all = Club.alphabetical.limit(10)
  end

  def all
    @letter = params[:letter] || "a"
    @this_letter = Club.where("title like '#{@letter}%'")
  end

  def popular
    @page = (params[:page] || 0).to_i
    @clubs = Club.popular.limit(50).offset(@page * 50)
    @random = Club.random.limit(22)
    @all = Club.alphabetical.limit(22)
  end

  def show
    @match_against_photo = @current_player.photos.approved_or_confirmed.not_coupled.first
    @photos = @club.candidate_pairs_by_profile(@match_against_photo, 20, seen_player_ids).map(&:other_photo)

    unless @photos.empty?
      other_clubs_raw = @photos.map(&:player).flatten.map(&:clubs).flatten
      @other_clubs = other_clubs_raw.inject(Hash.new{0}) { |map, club| map[club] += 1; map }.to_a.sort { |a,b| b[1] <=> a[1] }
    end

    if @photos.length < 20
      @gender_count = @photos.length
    else
      @gender_count = @club.players.joins(:photos).where("players.gender = ?", Gendery.opposite(@match_against_photo.gender)).where("photos.current_state = 'approved'").uniq.count
    end
    @other_gender_count = @club.interests_count - @gender_count
  end

  def photo
    @matching_photo = @current_player.photos.approved_or_confirmed.not_coupled.first
    @photo = Photo.joins(:player => :clubs).find(Integer.unobfuscate(params[:selected]))
    other_photos = @club.candidate_pairs_by_profile(@matching_photo, 10, seen_player_ids).map(&:other_photo)
    @other_photos = (other_photos - [@photo])[0...5]
    @other_clubs = Club.random.limit(30)
  end

  def join
    @current_player.interests.create(:title => @club.title, :club => @club)
    flash[:notice] = "You've just joined the \"#{@club.title}\" club."
    redirect_to :back
  end

  protected
  def set_tab
    @selected_tab = "labs"
    @selected_subtab = "club"
  end

  def load_club
    @club = Club.find_by_permalink(params[:id])
    redirect_to clubs_path if @club.nil?
  end

  def seen_player_ids
    # at some point don't show people who you've already said no to in the match_me_game

    return nil if @current_player.photos.empty?
    seen_photo_ids = MatchMeAnswer.where("player_id = ? AND target_photo_id = ? AND (game='club')", @current_player.id, @current_player.photos.first.id).select("other_photo_id").all.map(&:other_photo_id)
    return nil if seen_photo_ids.blank?
    Photo.where("id in (#{seen_photo_ids.join(",")})").select("player_id").all.map(&:player_id).uniq
  end

  def set_game_id
    if @current_player.photos.present?
      @game_id = params.include?(:game_id) ? params[:game_id] : Game.create(:player => @current_player).id
    end
  end
end
