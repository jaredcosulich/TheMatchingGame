class Combo < ActiveRecord::Base
  has_many :answers
  belongs_to :photo_one, :class_name => "Photo"
  belongs_to :photo_two, :class_name => "Photo"

  belongs_to :college

  validates :photo_one, :presence => true, :different_genders => true
  validates :photo_two, :presence => true, :different_genders => true
  before_save :set_percent

  accepts_nested_attributes_for :photo_one
  accepts_nested_attributes_for :photo_two

  has_one :response
  accepts_nested_attributes_for :response
  delegate :photo_one_answer, :photo_two_answer, :photo_one_answered_at, :photo_two_answered_at, :photo_one_unlocked?, :photo_two_unlocked?, :verified_good?, :verified_bad?, :verified?, :to => :response, :allow_nil => true

  scope :without_response, includes(:response).where("responses.id is null")

  has_many :combo_actions
  delegate :messages, :to => :combo_actions

  has_many :combo_scores
  has_many :photo_pairs
  attr_accessor :photo_one_pair, :photo_two_pair

  scope :not_seen, lambda { |player|
    return nil if player.nil? || player.new_record? 
    joins("LEFT OUTER JOIN answers ON combos.id = answers.combo_id and answers.player_id = #{player.id}").
    where("answers.id is null")
  }

  scope :college, lambda { |college_id| where("combos.college_id = ?", college_id) }
  scope :not_college, where("combos.college_id is null")

  scope :priority, where("photos.priority_until > now() OR photo_twos_combos.priority_until > now()")

  scope :active, where("combos.active = true")
  scope :inactive, where("combos.active = false")

  scope :random, order("random()")
  scope :active_random, where("combos.active = true").order("random()")
  scope :old, order("combos.created_at asc")

  scope :full, includes([:combo_scores, :photo_one, :photo_two])
  scope :with_response, includes([:photo_one, :photo_two, :response])
  scope :matching_full, includes([:combo_scores, :response, {:photo_one => {:player => [:profile, :user]}}, {:photo_two => {:player => [:profile, :user]}}])

  scope :more_yes, where("combos.yes_count > combos.no_count", 0).limit(10)
  scope :few_votes, where("combos.yes_count + combos.no_count < ?", 2).limit(10)
  scope :trending, where("combos.yes_count + combos.no_count BETWEEN ? AND ?", 3, 8).limit(10)
  scope :trending_yes, where("combo_scores.#{ComboScore.score_to_use_method} BETWEEN ? AND ? AND combos.yes_count >= ?", 55, 100, 2).limit(10)
  scope :trending_no, where("combo_scores.#{ComboScore.score_to_use_method} BETWEEN ? AND ? AND combos.no_count >= ?", 0, 45, 2).limit(10)

  scope :active_no, includes(:combo_scores).where("combos.active = true AND combos.no_count > 4 and combo_scores.#{ComboScore.score_to_use_method} < 30")
  scope :active_yes, includes(:combo_scores).where("combos.active = true AND combos.yes_count >= 6 and combo_scores.#{ComboScore.score_to_use_method} >= 75")
  scope :active_many_votes, where("combos.active = true AND combos.yes_count + combos.no_count > 12")

  scope :active_recent, lambda {
    joins(['INNER JOIN "photos" as p1 ON p1.id = "combos".photo_one_id', 'INNER JOIN "photos" as p2 ON p2.id = "combos".photo_two_id']).
        where("combos.active = true AND (p1.created_at >= ? OR p2.created_at >= ?)", 7.days.ago, 7.days.ago).
        order("random()")
  }
  
  scope :easy_good, lambda { |min_yes_percent|
    return nil if min_yes_percent.nil?
    where("combos.yes_percent >= #{min_yes_percent}")
  }

  scope :responded_to, includes([:photo_one, :photo_two, :response]).where("combos.active = false AND photos.current_state = 'approved' AND photo_twos_combos.current_state = 'approved' AND (photo_one_answer is not null OR photo_two_answer is not null)")
  scope :good_training, joins([:photo_one, :photo_two, :response]).where("combos.active = false AND photos.current_state = 'approved' AND photo_twos_combos.current_state = 'approved' AND (photo_one_rating > 5 AND photo_two_rating > 5)")
  scope :good_training_efficient, lambda { |combo_ids|
    joins([:photo_one, :photo_two]).
    where("combos.active = false AND photos.current_state = 'approved' AND photo_twos_combos.current_state = 'approved'").
    where("combos.id in (#{combo_ids.join(",")})")
  }
  scope :bad_training, joins([:photo_one, :photo_two, :response]).where("combos.active = false AND photos.current_state = 'approved' AND photo_twos_combos.current_state = 'approved' AND (photo_one_answer = 'bad' OR photo_two_answer = 'bad')")
  scope :bad_training_efficient, lambda { |combo_ids|
    joins([:photo_one, :photo_two]).
    where("combos.active = false AND photos.current_state = 'approved' AND photo_twos_combos.current_state = 'approved'").
    where("combos.id in (#{combo_ids.join(",")})")
  }

  scope :not_coupled, includes([:photo_one, :photo_two]).where("photos.couple_combo_id is null and photo_twos_combos.couple_combo_id is null")
  scope :active_coupled, includes([:photo_one, :photo_two, :response]).where("combos.active = false AND photos.current_state = 'approved' AND photo_twos_combos.current_state = 'approved' AND photos.couple_combo_id is not null and photo_twos_combos.couple_combo_id is not null and combos.yes_count + combos.no_count < #{Features::coupled_vote_count}")
  scope :inactive_coupled, includes([:photo_one, :photo_two, :response]).where("combos.active = false AND photos.current_state = 'approved' AND photo_twos_combos.current_state = 'approved' AND photos.couple_combo_id is not null and photo_twos_combos.couple_combo_id is not null and combos.yes_count + combos.no_count >= #{Features::coupled_vote_count}")

  scope :inactive_no, includes(:combo_scores).where("combos.active = false AND combos.no_count > 3 and combo_scores.#{ComboScore.score_to_use_method} < 30")
  scope :inactive_yes, includes(:combo_scores).where("combos.active = false AND combos.yes_count >= 5 and combo_scores.#{ComboScore.score_to_use_method} >= 75")
  scope :inactive_many_votes, where("combos.active = false AND combos.yes_count + combos.no_count > 10")

  scope :promotable, includes(:combo_scores).where("(combo_scores.#{ComboScore.score_to_use_method} > ? AND (combos.yes_count >= ? OR combos.yes_count + combos.no_count >= ?))", 55, 4, 8)

  scope :page, lambda { |page, limit| offset(page * limit).limit(limit) }

  scope :with_responses_for, lambda { |photos, responses|
    responses_sql = responses.blank? ? "is not null" : "in (#{responses.collect { |r| "'#{r}'"}.join(',')})"
    photo_ids = photos.map(&:id).join(",")
    joins(:response).
      where("(photo_one_id in (#{photo_ids}) AND photo_one_answer #{responses_sql}) OR (photo_two_id in (#{photo_ids}) AND photo_two_answer #{responses_sql})").
      order('combos.id DESC')
  }

  scope :with_activity, lambda { |photos|
    photo_ids = photos.map(&:id).join(',')
    joins(:combo_actions).where("photo_one_id in (#{photo_ids}) OR photo_two_id in (#{photo_ids})")
  }

  scope :with_interested, lambda { |photos|
    photo_ids = photos.map(&:id).join(',')
    joins(:response).where("(photo_one_id in (#{photo_ids}) AND photo_one_answer = 'interested') OR (photo_two_id in (#{photo_ids}) AND photo_two_answer = 'interested')")
  }

  scope :with_other_interested, lambda { |photos|
    photo_ids = photos.map(&:id).join(',')
    joins(:response).where("(photo_one_id in (#{photo_ids}) AND photo_two_answer = 'interested' AND photo_one_answer != 'bad') OR (photo_two_id in (#{photo_ids}) AND photo_one_answer = 'interested' AND photo_two_answer != 'bad')")
  }

  scope :without_responses_for, lambda { |photo|
    includes(:response).
      where("(photo_one_id = ? AND (responses.id is null OR photo_one_answer is null)) OR (photo_two_id = ? AND (responses.id is null OR photo_two_answer is null))", photo.id, photo.id).
      order('combos.id DESC')
  }


  scope :awaiting_responses_for, lambda { |photo, responses|
    responses_sql = responses.blank? ? "is not null" : "in (#{responses.collect { |r| "'#{r}'"}.join(',')})"
    joins(:response).
      where("(photo_one_id = ? AND photo_two_answer #{responses_sql} AND photo_one_answer is null) OR (photo_two_id = ? AND photo_one_answer #{responses_sql} AND photo_two_answer is null)", photo.id, photo.id).
      order('combos.id DESC')
  }

  delegate :photo_one_answer, :photo_two_answer, :to => :response, :allow_nil => true

  scope :for_photos, lambda{|photo_one_id, photo_two_id|
    where("(photo_one_id = ? AND photo_two_id = ?) OR (photo_two_id = ? AND photo_one_id = ?)", photo_one_id, photo_two_id, photo_one_id, photo_two_id)
  }

  scope :for_photo, lambda{|photo_id|
    where("(combos.photo_one_id = ?) OR (combos.photo_two_id = ?)", photo_id, photo_id)
  }

  def self.find_by_photo_ids(photo_one_id, photo_two_id)
    Combo.find(:first,
               :conditions => ["(photo_one_id = ? AND photo_two_id = ?) OR (photo_two_id = ? AND photo_one_id = ?)",
                               photo_one_id, photo_two_id, photo_one_id, photo_two_id]
    )
  end

  def self.find_or_create_by_photo_ids(photo_one_id, photo_two_id)
    find_by_photo_ids(photo_one_id, photo_two_id) || Combo.create!(:photo_one_id => photo_one_id, :photo_two_id => photo_two_id)
  end

  def self.exists_for_photo_ids?(photo_one_id, photo_two_id)
    find_by_photo_ids(photo_one_id, photo_two_id).present?
  end

  def as_json(options=nil)
    cresults = {:yes => yes_count, :no => no_count}
    results = {:yes => yes_count, :no => no_count} if fake_predicted?
    results = verified_good? ? true : (verified_bad? ? false : {:yes => yes_count, :no => no_count}) if results.nil?
    {
      :id => id,
      :one => photo_one.image.url,
      :one_interests => (interests = photo_one.interests).blank? ? "" : interests.map(&:title).join(", "),
      :two => photo_two.image.url,
      :two_interests => (interests = photo_two.interests).blank? ? "" : interests.map(&:title).join(", "),
      :verified => verified?,
      :results => results,
      :cresults => cresults,
      :choco => choco,
      :college_id => college_id
    }
  end

  def add_answer(answer)
    self.yes_count += 3 if answer == '3y'
    self.no_count += 3 if answer == '3n'
    self.yes_count += 2 if answer == '2y'
    self.no_count += 2 if answer == '2n'
    self.yes_count += 1 if answer == 'y'
    self.no_count += 1 if answer == 'n'
    save!
  end

  def recalculate!
    yes_count = 0
    no_count = 0
    answers.each { |a| a.answer == 'y' ? (yes_count += 1) : (no_count += 1)}
    self.yes_count = yes_count
    self.no_count = no_count
    save!
  end

  def set_percent
    self.yes_percent = (self.yes_count == 0 && self.no_count == 0) ? 0 : ((self.yes_count.to_f / (self.yes_count + self.no_count).to_f) * 100).to_i
  end

  def total_votes
    yes_count + no_count
  end

  def unanimous?
    yes_count == 0 || no_count == 0
  end

  def strength
    return "is not sure about this match yet" if yes_count + no_count <= 3
    case yes_percent
      when  0...40: "thinks this is not a match"
      when 40...60: "thinks this is a possible match"
      when 60...80: "thinks this is a good match"
      when 80..100: "thinks this is a great match"
    end
  end

  def other_photo(photo)
    photos.detect { |p| p != photo }
  end

  def other_photo_id(photo_id)
    photo_ids.detect { |id| id != photo_id }
  end

  def photo_ids
    [photo_one_id, photo_two_id]
  end

  def photos
    [photo_one, photo_two]
  end

  def <=>(other)
    id <=> other.id
  end

  def yes_choco
    response.try(:creation_reason) == "mutual_match_me" ?
        100 - choco :
        choco_percent(100 - no_percent)
  end

  def no_choco
    100 - yes_choco
  end

  def choco_percent(percent)
    return percent - choco if percent == 100
    return percent + choco if percent == 0
    percent
  end

  def no_percent
    yes_count + no_count > 0 ? no_count * 100 / (yes_count + no_count) : 0
  end

  def choco
    (id % 10) + 6
  end

  def status
    if response
      his_photo, her_photo = photo_one.gender == "m" ? [:photo_one, :photo_two] : [:photo_two, :photo_one]
      his_answer = response.send("#{his_photo}_answer")
      her_answer = response.send("#{her_photo}_answer")

      return case his_answer
        when 'bad'
          case her_answer
            when 'bad': :no_bn
            when nil: :no_hn
            when 'good', 'uninterested', 'interested': :no_sy_hn
          end
        when nil
          case her_answer
            when 'bad': :no_sn
            when nil: :good_inactive
            when 'good', 'uninterested', 'interested': :likely_sy
          end
        when 'good', 'uninterested', 'interested'
          case her_answer
            when 'bad': :no_hy_sn
            when nil: :likely_hy
            when 'good', 'uninterested', 'interested': :match
          end
        when
          case her_answer
            when 'bad': :no_hy_sn
            when nil: :likely_hy
            when 'good', 'uninterested', 'interested': :match
          end
      end

    end

    return :collecting if total_votes < 3 && active?
    prefix = case yes_percent
      when 0...30: "bad_"
      when 30...55: "unlikely_"
      else "good_"
    end

    "#{prefix}#{active? ? 'active' : 'inactive'}".to_sym
  end

  def status_string
    return "Looking Like a Possibility - Still In Play" if fake_predicted?
    case status
      when :collecting: "Not Enough Data - Still In Play"
      when :bad_active: "Bad Match - Removing From Play"
      when :bad_inactive: "Bad Match - Removed From Play"
      when :unlikely_active: "Unlikely Match - Still In Play"
      when :unlikely_inactive: "Unlikely Match - Removed From Play"
      when :good_active: "Looking Like a Possibility - Still In Play"
      when :good_inactive: "Good Match - Upgraded to Good Match Status"
      when :likely_hy: "Possible Match - One of them has said yes, waiting for the other answer"
      when :likely_sy: "Possible Match - One of them has said yes, waiting for the other answer"
      when :no_hn: "Not a Match - We asked and they didn't think it was a good match"
      when :no_sn: "Not a Match - We asked and they didn't think it was a good match"
      when :no_sy_hn: "Not a Match - We asked and they didn't think it was a good match"
      when :no_hy_sn: "Not a Match - We asked and they didn't think it was a good match"
      when :no_bn: "Not a Match - We asked and they didn't think it was a good match"
      when :match: "Match - They both thought it was good match!"
      when :connect: "Connection - They've decided to connect!"
    end
  end

  def status_image
    return "half_green_arrow.png" if fake_predicted?
    case status
      when :collecting: "unknown_circle.png"
      when :bad_active: "red_arrow.png"
      when :bad_inactive: "red_arrow.png"
      when :unlikely_active: "half_red_arrow.png"
      when :unlikely_inactive: "half_red_arrow.png"
      when :good_active: "half_green_arrow.png"
      when :good_inactive: "green_arrow.png"
      when :likely_hy: "half_green_circle.png"
      when :likely_sy: "half_green_circle.png"
      when :no_hn: "red_circle.png"
      when :no_sn: "red_circle.png"
      when :no_sy_hn: "red_circle.png"
      when :no_hy_sn: "red_circle.png"
      when :no_bn: "red_circle.png"
      when :match: "green_circle.png"
      when :connect: "green_circle.png"
      else
        "blank.png"
    end
  end

  def response_state(player)
    photo_position = photo_position_for(player)
    return unless photo_position
    return "unanswered" unless response
    answer = response.send("#{photo_position}_answer")
    answer.blank? ? "unanswered" : answer
  end

  def other_actor(player)
    send(other_position_for(player)).player
  end

  def photo_for(player)
    position = photo_position_for(player)
    send(position) unless position.nil?
  end

  def photo_emailed(photo)
    return photo_one_emailed_at if photo == photo_one
    return photo_two_emailed_at if photo == photo_two
  end

  def photo_position_for(thing)
    return "photo_one" if photo_one == thing || photo_one.player == thing
    return "photo_two" if photo_two == thing || photo_two.player == thing
  end

  def other_position_for(thing)
    return "photo_one" if photo_position_for(thing) == "photo_two"
    return "photo_two" if photo_position_for(thing) == "photo_one"
  end

  def points_for_other_answer(photo)
    return -1 unless response
    return case response.send("#{other_position_for(photo)}_answer")
      when "bad": 0
      when "good": 1
      when "uninterested": 2
      when "interested": 3
      else -1
    end
  end

  def message(sender, message)
    combo_actions.create(:photo => sender, :action => "message", :message => message)
  end

  def connect(actor, message)
    combo_actions.create(:photo => actor, :action => "connect", :message => message)
  end

  def cancel(actor)
    combo_actions.create(:photo => actor, :action => "cancel")
  end

  def connected?
    all_actions = combo_actions.not_messages.full.reverse
    first = all_actions.first
    first.present? && first.action == 'connect'
  end

  def reciprocated?
    combo_actions.select{ |ca| ca.action == "connect" || ca.action == "message"}.map(&:photo).uniq.length > 1
  end

  def connection_action
    connected? ? "message" : "connect"
  end

  def couple_complete?
    yes_count + no_count >= Features.coupled_vote_count
  end

  def couple_combo?
    photo_one.couple_combo_id == id && photo_two.couple_combo_id == id
  end

  def score
    combo_scores.empty? ? nil : combo_scores.first.score
  end

  def score_to_use
    combo_scores.empty? ? nil : combo_scores.first.score_to_use
  end

  def unlocked_for?(player)
    send("#{photo_position_for(player)}_unlocked?")
  end

  def archived_for?(player)
    archived_at = response.send("#{photo_position_for(player)}_archived_at")
    return false if archived_at.nil?
    unread_messages = combo_actions.select { |ca| ca.photo_id != photo_for(player).id && ca.viewed_at.nil? }
    return true if archived_at.present? && unread_messages.empty?
    unread_messages.sort_by(&:created_at).last.created_at > archived_at
  end

  def unread_messages(player)
    combo_actions.where("photo_id != ?", photo_for(player).id).where("viewed_at is null")
  end

  def photo_one_pair
    @photo_one_pair || photo_pairs.detect{|pair|pair.photo_id == photo_one.id}
  end

  def photo_two_pair
    @photo_two_pair || photo_pairs.detect{|pair|pair.photo_id == photo_two.id}
  end

  COMBOS_TO_FAKE_PREDICT = [
    52176,
#    52131,
    52238,
    54267,
    54260,
    54266,
    30542,
    53918,
    53901,
    53891,
    53429,
    52537,
    51761,
    50301,
    48689,
    47646,
    56701,
    47449,
    34907,
    46509,
    54319,
    38410,
    40647,
    56198,
    57250,
    31538,
    37090,
    26096,
    52568,
    25468,
    30004,
    56640,
    19716,
    44933,
    14221,
    70044,
    16756,
    59892,
    42140,
    34665,
    40956,
    24831,
    54787,
    6018,
    15362,
    49784,
    52848,
    90249,
    89165,
    64140,
    91992,
    96754,
    59396, 
    90667,
    94477,
    110150,
    109131,
    100856,
    99624
  ]

  scope :not_fake_predicted, where("combos.id not in (#{COMBOS_TO_FAKE_PREDICT.join(",")})")

  scope :fake_predicted, lambda { |combos|
    existing_photo_ids = combos.map(&:photos).flatten.map(&:id).join(",")
    existing_photo_ids = "0" if existing_photo_ids.blank?
    where("combos.id in (#{COMBOS_TO_FAKE_PREDICT.join(",")})").
    where("photo_one_id not in (#{existing_photo_ids})").
    where("photo_two_id not in (#{existing_photo_ids})")
  }

  def fake_predicted?
    COMBOS_TO_FAKE_PREDICT.index(id).present?
  end

end


