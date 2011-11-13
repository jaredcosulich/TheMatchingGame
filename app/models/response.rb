class Response < ActiveRecord::Base
  belongs_to :combo

  before_save :set_answered_at
  after_save :update_combo_changed_at
  after_save :notify_other_player
  after_save :notify_both_players_on_mutual_good

  delegate :photo_one, :photo_two, :to => :combo
  delegate :photo_one_id, :photo_two_id, :to => :combo

  scope :good, where("responses.photo_one_rating > 5 and responses.photo_two_rating > 5")
  scope :bad, where("responses.photo_one_rating < 5 or responses.photo_two_rating < 5")
  scope :random, order("random()")

  scope :not_seen, lambda { |player|
    return nil if player.nil? || player.new_record?
    joins("LEFT OUTER JOIN answers ON responses.combo_id = answers.combo_id and answers.player_id = #{player.id}").
    where("answers.id is null")
  }

  def yes_no(photo_position)
    answer = send("#{photo_position}_answer")
    case answer
      when 'bad': "no"
      when 'good', 'interested', 'uninterested': "yes"
      else "nothing yet"
    end
  end
  
  def last_answer_position
    return nil if photo_one_answer.nil? && photo_two_answer.nil?
    return "photo_one" if photo_two_answer.nil?
    return "photo_two" if photo_one_answer.nil?
    (photo_one_answered_at > photo_two_answered_at) ? "photo_one" : "photo_two"
  end

  def last_full_answer
    photo_position = last_answer_position
    return nil if photo_position.nil?
    photo = combo.send(photo_position)
    "#{photo.he_she.camelize} said #{yes_no(photo_position)}"
  end

  def self.notified_unnotified
    already_notified = [3101, 4594, 1831, 1155, 1763, 447, 662, 466, 426, 405, 384, 358]
    Response.find(:all, :conditions => "photo_one_answer = 'interested' OR photo_two_answer = 'interested'").collect do |response|
      next if already_notified.include?(response.combo_id)
      notified = response.photo_one_answer == 'interested' ? :photo_two : :photo_one
      next if [response.photo_one_answer, response.photo_two_answer].compact.length < 2
      response.notify_other_player(notified)
    end.compact
  end

  def notify_other_player(force_other_position = nil)
    return unless force_other_position
    return unless (other_position = force_other_position || other_photo_if_becoming_interested)
    return if send("#{other_position}_answer") == 'bad'
    other_player = send(other_position).player
    return unless other_player && other_player.connectable?
    Emailing.delay(:priority => 3).deliver("interested_notification", other_player.user.id, combo.id)
    [other_player.user.id, combo.id]
  end

  def notify_both_players_on_mutual_good(force=false)
    return if photo_one_answer.blank? || photo_one_answer == 'bad'
    return if photo_two_answer.blank? || photo_two_answer == 'bad'
    return unless force || photo_one_answer_was.blank? || photo_one_answer_was == "bad" || photo_two_answer_was.blank? || photo_two_answer_was == "bad"
    return if photo_one.couple_combo_id.present? || photo_two.couple_combo_id.present?
    if !photo_one.connectable? || !photo_two.connectable?
      Emailing.delay(:priority => 3).deliver("mutual_good_not_connected_notification", photo_one.player.user.id, combo.id) unless photo_one.connectable?
      Emailing.delay(:priority => 3).deliver("mutual_good_not_connected_notification", photo_two.player.user.id, combo.id) unless photo_two.connectable?
    else
      Emailing.delay(:priority => 3).deliver("mutual_good_notification", photo_one.player.user.id, combo.id) if photo_one.player.user.present?
      Emailing.delay(:priority => 3).deliver("mutual_good_notification", photo_two.player.user.id, combo.id) if photo_two.player.user.present?
    end
  end

  def other_photo_if_becoming_interested
    return :photo_two if photo_one_answer == "interested" && photo_one_answer_was != "interested"
    return :photo_one if photo_two_answer == "interested" && photo_two_answer_was != "interested"
  end

  def set_answered_at
    if photo_one_answer == "unanswered"
      self.photo_one_answer = nil
      self.photo_one_rating = nil
    end

    if photo_two_answer == "unanswered"
      self.photo_two_answer = nil
      self.photo_two_rating = nil
    end

    self.photo_one_answered_at = Time.now unless photo_one_answer == photo_one_answer_was
    self.photo_two_answered_at = Time.now unless photo_two_answer == photo_two_answer_was
  end

  def scored_at
    return [photo_one_answered_at, photo_two_answered_at].compact.min if verified_bad?
    return [photo_one_answered_at, photo_two_answered_at].compact.max if verified_good?
  end

  def update_combo_changed_at
    self.combo.update_attribute(:state_changed_at, self.updated_at)
  end

  def verified_good?
    [yes_no(:photo_one), yes_no(:photo_two)] == ["yes", "yes"]
  end

  def verified_bad?
    [yes_no(:photo_one), yes_no(:photo_two)].include?("no")      
  end

  def verified?
    verified_good? || verified_bad?
  end

  scope :without_revealed_at, where("revealed_at is null and (photo_one_answer is null OR photo_one_answer != 'bad') and (photo_two_answer is null OR photo_two_answer != 'bad')").includes(:combo)
  scope :unrevealed, where("revealed_at > now()").includes(:combo)
  
  def self.reveal_some
    latest_revealed_at_by_photo = Hash.new{|h,k| h[k]=-1}
    without_revealed_at.order("combos.yes_percent desc").each do |response|
      revealed_at = 0
      [response.combo.photo_one_id, response.combo.photo_two_id].each do |photo_id|
        if latest_revealed_at_by_photo[photo_id] >= revealed_at
          revealed_at = latest_revealed_at_by_photo[response.combo.photo_one_id] + 8
        end
      end

      latest_revealed_at_by_photo[response.combo.photo_one_id] = revealed_at
      latest_revealed_at_by_photo[response.combo.photo_two_id] = revealed_at
      response.update_attribute(:revealed_at, revealed_at.hours.from_now)
    end
  end

  def self.create_for_all_promotable_combos
    Combo.promotable.without_response.find_in_batches(:batch_size => 100) do |combos|
      Response.transaction do
        combos.map(&:save)
      end
    end
  end

end
