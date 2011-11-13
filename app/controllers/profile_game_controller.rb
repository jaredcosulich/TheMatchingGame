class ProfileGameController < ApplicationController
  before_filter :ensure_registered_user, :except => [:interests]
  before_filter :set_tab

  @@profiles_with_fb_links = ActiveRecord::Base.connection.select_values("select id from profiles where about like '%facebook%'")
  @@profiles_with_emails = ActiveRecord::Base.connection.select_values("select id from profiles where about like '%@%'")


  def index
    @photo = Photo.approved \
                  .joins(:player => :profile) \
                  .not_college \
                  .where('(bucket = 4 or bucket = 5) and couple_combo_id is null') \
                  .where("about is not null and about != ''") \
                  .where(params.include?(:g) ? ["photos.gender = ?", params[:g]] : nil) \
                  .where("profiles.id not in (?) and profiles.id not in (?)", @@profiles_with_fb_links, @@profiles_with_emails) \
                  .order('random()') \
                  .limit(1).first

    @profiles = Profile \
                  .joins(:player => :photos) \
                  .where("photos.college_id is null") \
                  .where("about is not null and about != ''") \
                  .where("couple_combo_id is null and photos.gender = ?", @photo.gender) \
                  .where("profiles.id not in (?)", @photo.player.profile.id) \
                  .where("profiles.id not in (?) and profiles.id not in (?)", @@profiles_with_fb_links, @@profiles_with_emails) \
                  .order("random()") \
                  .limit(2)

    @profiles << @photo.player.profile
    
  end

  def interests
    @highlighted_player = Player.joins(:interests, :photos).find(Integer.unobfuscate(params[:highlighted])) if params.include?(:highlighted)
    gender = (params[:g] || ((@current_player.nil? || @current_player.gender.blank?) ? "f" : Gendery.opposite(@current_player.gender)))
    @interesting_players = Player.joins(:interests, :photos).
                                  where(@current_player.user.nil? ? "(bucket = 4 or bucket = 5)" : nil).
                                  where("photos.current_state = 'approved'").
                                  where("photos.college_id is null").
                                  where("players.gender = ?", gender).
                                  where(@highlighted_player.present? ? "players.id != #{@highlighted_player.id}" : nil).
                                  where(seen_player_ids.present? ? "players.id not in (#{seen_player_ids.join(',')})" : nil).
                                  order("random()").limit(6)
    set_game_id
    @selected_subtab = "interests"
  end

  def discover
    already_seen_player_ids = seen_player_ids
    if params.include?(:highlighted)
      @highlighted_photo = Photo.includes(:player => :interests).find(Integer.unobfuscate(params[:highlighted]))
    else
      @highlighted_photo = Photo.joins(:player => :interests).approved.not_coupled.not_college.
                                 where("bucket in (3,4)").
                                 where("photos.gender = ?", params[:g] || (@current_player.gender.blank? ? "f" : Gendery.opposite(@current_player.gender))).
                                 where(already_seen_player_ids.present? ? "photos.player_id not in (#{already_seen_player_ids.join(',')})" : nil).
                                 order("bucket desc, random()").first
    end

    base_query = Photo.approved.not_coupled.random.not_college.
                       where("photos.gender = ?", @highlighted_photo.gender).
                       where("photos.id != ?", @highlighted_photo.id).
                       where(already_seen_player_ids.present? ? "photos.player_id not in (#{already_seen_player_ids.join(',')})" : nil)

    other_photos = base_query.joins(:player => :interests).where("bucket = 4 OR bucket = 5").limit(1).flatten
    other_photos << base_query.joins(:player => :interests).where("bucket = ? OR bucket = ?", @highlighted_photo.bucket, @highlighted_photo.bucket + 1).limit(3).flatten
    other_photos << base_query.joins(:player).where(other_photos.empty? ? nil : "photos.id not in (#{other_photos.map(&:id).join(",")})").limit(20).flatten
    @other_photos = other_photos.flatten.uniq[0..4].shuffle
    
    interests = @other_photos.collect(&:player).collect(&:interests).flatten.shuffle.uniq[0..3]
    interests << Interest.joins(:player => :photos).where("photos.current_state = 'approved' and photos.couple_combo_id is null and players.gender = ?", @highlighted_photo.gender).order("random()").limit(10)
    @interests = interests.flatten.uniq[0..4].shuffle
    set_game_id
    @selected_subtab = "discover"
  end

  def discounts
    @selected_subtab = "discounts"
  end

  def labs

  end

  def innovative

  end

  protected
  def seen_player_ids
    # at some point don't show people who you've already said no to in the match_me_game
    
    return nil if @current_player.photos.empty?
    seen_photo_ids = MatchMeAnswer.where("player_id = ? AND target_photo_id = ? AND (game='interests' OR game='discover')", @current_player.id, @current_player.photos.first.id).select("other_photo_id").all.map(&:other_photo_id)
    return nil if seen_photo_ids.blank?
    Photo.where("id in (#{seen_photo_ids.join(",")})").select("player_id").all.map(&:player_id).uniq
  end

  def set_game_id
    if @current_player.photos.present?
      @game_id = params.include?(:game_id) ? params[:game_id] : Game.create(:player => @current_player).id
    end
  end

  def set_tab
    @selected_tab = "labs"
  end
end
