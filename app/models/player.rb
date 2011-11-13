class Player < ActiveRecord::Base
  include Gendery
  
  has_one :user
  has_one :profile
  has_one :facebook_profile

  belongs_to :preferred_profile, :polymorphic => true
  belongs_to :college

  has_one :referral
  has_one :help_response
  has_one :referrer, :through => :referral
  has_many :photos, :conditions => "current_state != 'removed'"
  has_many :games
  has_many :answers
  has_one :player_stat
  has_many :interests, :order => "id asc"
  has_many :clubs, :through => :interests
  has_many :question_answers
  has_many :questions
  has_many :score_events
  has_many :challenge_players
  has_many :challenges, :through => :challenge_players
  has_many :player_badges, :order => "player_badges.created_at desc"
  has_many :badges, :through => :player_badges, :order => "player_badges.created_at desc"

  delegate :name_age_and_place, :first_name_or_anonymous, :full_name, :age, :birthdate, :location_name, :first_name, :last_name, :sexual_orientation, :to => :preferred_profile, :allow_nil => true
  delegate :about, :first_date, :to => :profile, :allow_nil => true
  delegate :admin?, :email, :blank_email?, :fb_id, :sufficient_credits?, :subscribed?, :to => :user, :allow_nil => true
  delegate :correct_count, :incorrect_count, :answer_weight, :answer_count, :percentile, :accuracy, :points, :to => :current_stat, :allow_nil => true

  accepts_nested_attributes_for :profile, :update_only => true
  accepts_nested_attributes_for :user, :update_only => true

  before_create :set_same_sex
  after_create :create_player_stat
  after_save :notify_mutual_connections

  scope :leaderboard, lambda { |player|
    includes([:player_stat, :profile, :facebook_profile]).
      where("#{"players.id = #{player.id} OR " unless player.nil?}(profiles.id is not null OR facebook_profiles.id is not null)")
  }

  scope :active_daters, joins([:photos, :user]).where(:connectable => true).where("photos.current_state = 'approved'")

  def visible_name(player=nil)
    (preferred_profile.nil? || preferred_profile.visible_name.blank?) ? (player == self ? "You" : "Matcher #{id}") : preferred_profile.visible_name
  end

  def current_stat
    latest_score_event = score_events.last_updated.first
    return player_stat if latest_score_event.nil?
    if answers.count != 0 && latest_score_event.updated_at > player_stat.updated_at
      player_stat.save!
    end
    player_stat.reload
  end

  def recent_games
    games.recent.find(:all, :limit => 3)
  end

  def last_game_answers
    games.empty? ? [] : games.last.answers.full
  end

  def has_matching_photos?
    photos.not_coupled.present?
  end

  def last_game_perfect?
    answers = last_game_answers
    answers.present? && answers.select{ |a|a.incorrect? }.empty? && answers.select{ |a|a.correct? }.length > 3
  end

  def combos
    Combo.find(:all, :joins => {:answers => :game}, :conditions => ["games.player_id=?", id])
  end

  def connections
    return [] if photos.empty?
    (Combo.not_coupled.full.with_activity(photos) + Combo.not_coupled.full.with_other_interested(photos)).uniq
  end

  def migrate_games_from(other_player_id)
    other_player = Player.find_by_id(other_player_id)
    return if other_player.nil?
    return unless other_player.user.nil?
    answered_combos = answers.collect(&:combo)
    answers_to_migrate = other_player.answers.reject{|a|answered_combos.include?(a.combo)}.reject{|a| a.combo.photo_one.player_id == id || a.combo.photo_two.player_id == id}
    unless answers_to_migrate.empty?
      game = Game.create(:player => self)
      connection.execute("update answers set game_id = #{game.id}, player_id = #{id} where id in (#{answers_to_migrate.map(&:id).join(',')})")
    end
  end

  def score_history
    aw = PlayerStat::AnswerWeight.new
    scores = score_events.event_ordered.all.collect do |score_event|
      score_event.score(aw)
    end
    scores.unshift(0)
    scores
  end

  def update_from_facebook(fb_info)
    fb_id = fb_info[:uid] || fb_info[:id]
    raise "Error: update_from_facebook called with data for #{fb_id} but user linked to #{user.fb_id}" if user.fb_id.present? && user.fb_id != fb_id.to_i

    begin
      (facebook_profile || build_facebook_profile).merge_fb_info(fb_info)
      facebook_profile.save! if facebook_profile

      if fb_info[:email].present? && anonymous?
        user.email = fb_info[:email]
        user.save!
      end

      unless fb_info[:sex].blank?
        self.gender = fb_info[:sex][0, 1]
        save!
      end
      return true
    rescue
      return false
    end
  end

  def update_interests(updated_interests)
    if updated_interests.present?
      updated = updated_interests.map{ |info| info[:title]}.uniq.reject { |title| title.blank? }
      interests.each do |interest|
        update = updated.shift
        if update.nil?
          interest.destroy
        else
          interest.update_attributes(:title => update) unless interest.title == update
        end
      end
      updated.each do |interest|
        interests.create(:title => interest)
      end
    end
  end

  def anonymous?
    user.nil? || (user.email.index(/fb_\d+@thematchinggame.com/)).present?
  end

  def gender_with_unknown
    gender || 'u'
  end

  def remove_duplicate_answers
    combo_id_map = {}
    answers.each do |answer|
      answer.update_attribute(:game_id, 0) if combo_id_map[answer.combo_id]
      combo_id_map[answer.combo_id] = true
    end
  end

  def self.with_duplicate_users
    ids = connection.select_values('select player_id from users group by 1 having count(*) > 1')
    ids.present? ? Player.where("id in (#{ids.join(",")})") : []
  end

  def merge_duplicate_users
    users = User.where(:player_id => id)
    return if users.length < 2

    fb_users, email_users = users.partition{|user|user.email =~ /fb_\d+@thematchinggame.com/}
    if fb_users.length > 0 && email_users.length > 0
      email_users.first.update_attribute(:fb_id, fb_users.first.fb_id)
      fb_users.first.destroy
    end
  end
  
  def answer_counts
    {
    "existing_correct" => existing_correct_count,
    "existing_incorrect" =>
      (
        answers.existing.yes.full.any_negative.count +
        answers.existing.no.full.both_positive.count
      ),
    "predicted_correct" =>
      (
        answers.predicted.yes.full.both_positive.count +
        answers.predicted.no.full.any_negative.count
      ),
    "predicted_incorrect" =>
      (
        answers.predicted.yes.full.any_negative.count +
        answers.predicted.no.full.both_positive.count
      )
    }
  end

  def existing_correct_count
    answers.existing.yes.full.both_positive.count +
    answers.existing.no.full.any_negative.count
  end

  def timeline_data
    aw = PlayerStat::AnswerWeight.new
    answers.find(:all, :order => "created_at asc", :include => [:game, {:combo => [:response, :photo_one, :photo_two]}]).collect do |a|
      aw << a
      "[new Date(#{aw.answer_count.days.from_now.to_json}), #{1000 * (aw.value || 1)}]"
    end
  end

  def sparkline_data
    aw = PlayerStat::AnswerWeight.new
    answers.find(:all, :order => "created_at asc", :include => [:game, {:combo => [:response, :photo_one, :photo_two]}]).collect do |a|
      aw << a
      ((aw.value || 1) * 1000).to_i
    end.compact
  end

  def answer_groups(query=nil, offset=0)
    group = answers.limit(20).offset(offset).order('answers.id desc')
    case query
      when "existing_correct"
        group.existing.correct
      when "existing_incorrect"
        group.existing.incorrect
      when "predicted_correct"
        group.predicted.correct
      when "predicted_incorrect"
        group.predicted.incorrect
      else
        group.correct_or_incorrect
    end
  end

  def prediction_progress(days)
    base_scope = answer_scope.unread

    base_scope.predicted_with_response_since(days.days.ago)
  end

  def answer_scope
    Answer.where("game_id in (select id from games where player_id = ?)", id)
  end

  def notify_mutual_connections
    return unless connectable? && !connectable_was
    photos.each do |photo|
      photo.combos.each do |combo|
        combo.response.notify_both_players_on_mutual_good(true) unless combo.response.nil?
      end
    end
  end

  def good_training_yes_count_threshold
    case games.length
      when 0..1: 80
      when 2..3: 70
      when 3..4: 60
      else nil
    end
  end

  def level
    return 3 if games.length > 4 && (player_stat.accuracy || 0) > 60
    return 2 if games.length > 2
    return 1
  end

  def distance_from(other_player)
    lat_lng.distance_from(other_player.lat_lng) rescue 300
  end

  def distance_score(other_player)
    distance = distance_from(other_player)
    distance == 0 ? -1 : (Math.log(distance / 20) / Math.log(3)).to_i rescue 3
  end

  DEFAULT_LAT = 39.833
  DEFAULT_LNG     = 98.583
  DEFAULT_LAT_LNG = GeoKit::LatLng.new(DEFAULT_LAT, DEFAULT_LNG)

  def lat_lng
    return GeoKit::LatLng.new(profile.location_lat, profile.location_lng) if profile && profile.location_lat.present? && profile.location_lng.present?
    return GeoKit::LatLng.new(geo_lat, geo_lng) if geo_lat.present? && geo_lng.present?
#    return geocode_by_ip_or_default(user)
    return DEFAULT_LAT_LNG
  end

  def geocode_by_ip_or_default(user)
    return DEFAULT_LAT_LNG if user.nil?
    return DEFAULT_LAT_LNG if user.current_login_ip.blank?
    Rails.logger.debug "GEOCODING #{user.current_login_ip}"
    Geokit::Geocoders::MultiGeocoder.geocode(user.current_login_ip)
  end

  def age_score(other_player)
    years = (birthdate - other_player.birthdate) / 365 rescue nil
    delta = years * (((gender == "m" && years <= 0) || (gender == "f" && years > 0)) ? 1 : 2.5) rescue 5.5
    (delta / 2.5).to_i.abs
  end

  def primary_photo
    photos.detect { |p| (p.approved? || p.paused?) && p.couple_combo_id.nil? }
  end

  def college_photo
    return nil if college_id.nil?
    photos.where("college_id = ?", college_id).first
  end

  def age_bucket
    case
      when age.nil?: "na"
      when age < 22: "18-22"
      when age < 26: "22-26"
      when age < 30: "26-30"
      when age < 35: "30-35"
      when age < 40: "35-40"
      when age < 50: "40-50"
      when age < 60: "50-60"
      else "60-"
    end
  end

  def self.check_slug(slug)
    return false
  end

  def self.location_data(gender)
    location_sql = <<-sql
      select players.id, min(info.id) as photo_id, min(info.lat) as lat, min(info.lng) as lng
      from players, photos, photo_player_profile info
      where players.id = photos.player_id and
            photos.id = info.id and
            info.lat is not null and
            info.lng is not null and
            photos.current_state = 'approved' and
            photos.gender = '#{gender}' and
            photos.couple_combo_id is null
      group by players.id
      order by players.id desc
      limit 5000
    sql

    connection.select_all(location_sql).collect { |info| info["obfuscated_id"] = info["photo_id"].to_i.to_obfuscated; info }
  end

  def set_same_sex
    self.same_sex = false if same_sex.nil?
  end

  def all_badge_icons
    levels = [5,20,50,100,250,500,1000,5000]
    levels_achieved = []
    levels.reverse.each do |level|
      if player_stat.correct_count >= level
        levels_achieved << "#{level}_correct_badge"
      end
    end
    ([levels_achieved.shift] + badges.map(&:icon) + levels_achieved).compact
  end

end
