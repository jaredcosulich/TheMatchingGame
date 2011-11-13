class Photo < ActiveRecord::Base
  class MaxPhotosException < StandardError; end;
  class UnderAgeException < StandardError; end;

  include Gendery
  after_create :notify_admins

  has_one :flickr_photo, :dependent => :destroy
  belongs_to :couple_combo, :class_name => "Combo"
  belongs_to :player
  belongs_to :college
  delegate :user, :location_name, :interests, :to => :player, :allow_nil => true

  has_one :crop

  validates_format_of :gender, :with => /[mfu]/, :message => "is required"

  before_validation :check_max_approved_photos, :on => :create
  before_validation :check_age, :on => :create
  before_validation :set_defaults, :on => :create

  has_attached_file :image,
    PAPERCLIP_STORAGE_OPTIONS.merge(
    :styles => { :large => "600x600", :normal => "300x300", :thumbnail => "120x120", :preview => "60x60" },
    :processors => [:jcropper],
    :default_style => :normal,
    :default_url => "/images/loading.gif"
    )

  has_many :photo_pairs
  has_many :combos_as_photo_one, :class_name => "Combo", :foreign_key => :photo_one_id
  has_many :combos_as_photo_two, :class_name => "Combo", :foreign_key => :photo_two_id

  has_many :combo_actions_as_photo_one, :through => :combos_as_photo_one, :source => :combo_actions
  has_many :combo_actions_as_photo_two, :through => :combos_as_photo_two, :source => :combo_actions

  has_many :match_me_answers_as_target, :class_name => "MatchMeAnswer", :foreign_key => :target_photo_id
  has_many :match_me_answers_as_other, :class_name => "MatchMeAnswer", :foreign_key => :other_photo_id

  if ENV['PROCESS_IN_BACKGROUND']
    process_in_background :image
  end

  validates_attachment_presence :image, :message => "File must be a valid image"
  validates_attachment_content_type :image,
                                    :content_type => /image/,
                                    :message => "Make sure you are uploading an image file."

  scope :random, order("random()").limit(100)
  scope :unconfirmed, where(:current_state => 'unconfirmed')
  scope :unreviewed, where("current_state = 'confirmed' OR current_state = 'resubmitted' OR (player_id != 0 and bucket is null AND current_state = 'approved')")
  scope :approved, where(:current_state => 'approved')
  scope :approved_or_confirmed, where("current_state = 'approved' OR current_state = 'confirmed'")
  scope :not_coupled, where("couple_combo_id is null")
  scope :coupled, where("couple_combo_id is not null")
  scope :same_sex, lambda { |photo| where("same_sex = 't' and gender = ? and id != ?", photo.redundant_gender, photo.id) }
  scope :college, lambda { |college_id| where("college_id = ?", college_id) }
  scope :not_college, where("photos.college_id is null")

  scope :need_combos, lambda {
    conditions = <<-SQL
      SELECT photos.id
      FROM players, users, photos left join combos on (photos.id = combos.photo_one_id OR photos.id = combos.photo_two_id) and combos.active = true
      WHERE photos.player_id = players.id AND users.player_id = players.id
        AND users.last_request_at > '#{1.month.ago}'
        AND photos.player_id != 0
        AND photos.current_state= 'approved'
        AND photos.couple_combo_id is null
      GROUP BY 1
      HAVING count(combos.id) < 2 OR max(priority_until) > now()
    SQL
    where("id in (#{conditions})")
  }

  scope :within_one_bucket_of, lambda {|reference_photo|
    reference_photo.bucket.nil?? nil : where('bucket between ? and ?', reference_photo.bucket - 1, reference_photo.bucket + 1)
  }

  scope :opposite_gender_of, lambda {|reference_photo|
    where("same_sex = 'f'").
    where(:gender => Gendery.opposite(reference_photo.redundant_gender))
  }

  scope :excluding_photos, lambda {|excluded_photo_ids|
    where(excluded_photo_ids.empty? ? nil : "id not in (#{excluded_photo_ids.join(',')})")
  }

  scope :popular_ids_from_other_answer, lambda { |gender|
    select("photos.id"). \
    joins(:photo_pairs). \
    where("photo_pairs.other_photo_answer_yes is not null or photo_pairs.other_photo_answer_no is not null"). \
    where(gender.nil? ? nil : ["photos.gender = ?", gender]). \
    where("photos.current_state = 'approved'"). \
    group("photos.id"). \
    order("100 * sum(other_photo_answer_yes) / count(photo_pairs.id) desc")
  }


  delegate :connectable?, :first_name, :first_name_or_anonymous, :to => :player, :allow_nil => true

  include AASM
  aasm_column :current_state
  attr_protected :current_state
  aasm_initial_state :unconfirmed

  aasm_state :unconfirmed
  aasm_state :confirmed
  aasm_state :approved, :after_enter => [:generate_combos, :mail_approved], :after_exit => :check_approved_count
  aasm_state :rejected, :before_exit => :clear_reason, :after_enter => :mail_rejection_reason
  aasm_state :paused, :after_enter => :deactivate_combos
  aasm_state :paused_unapproved
  aasm_state :removed, :after_exit => :check_last_removed

  aasm_event :confirm do
    transitions :to => :confirmed, :from => [:unconfirmed]
  end

  aasm_event :approve do
    transitions :to => :approved, :from => [:confirmed, :rejected, :resubmitted], :guard => :has_gender?
  end

  aasm_event :reject do
    transitions :to => :rejected, :from => [:confirmed, :approved, :paused, :resubmitted]
  end

  aasm_event :resubmit do
    transitions :to => :unconfirmed, :from => [:rejected]
  end

  aasm_event :pause do
    transitions :to => :paused, :from => [:approved]
    transitions :to => :paused_unapproved, :from => [:confirmed]
  end

  aasm_event :resume do
    transitions :to => :approved, :from => [:paused], :guard => :check_max_approved_photos
    transitions :to => :confirmed, :from => [:paused_unapproved], :guard => :check_max_approved_photos
  end

  aasm_event :remove do
    transitions :to => :removed, :from => [:approved, :paused, :paused_unapproved, :confirmed, :rejected, :resubmitted]
  end

  def title
    return "Anonymous Person" if player_id == 0 || player.nil?
    return player.name_age_and_place || "Anonymous Person"
  end

  def visible_name
    return "Anonymous Person" if player_id == 0 || player.nil?
    return player.visible_name || "Anonymous Person"
  end

  def matched_with
    if gender == "m"
      player.same_sex? ? "Men" : "Women"
    else
      player.same_sex? ? "Women" : "Men"
    end
  end

  def status
    case current_state
      when 'unconfirmed': ["Unconfirmed", "Please confirm to begin matching"]
      when 'confirmed', 'resubmitted': ["Pending Approval", "Matching will begin once approved"]
      when 'approved': ["Matching", "Matching is in progress"]
      when 'rejected': ["Not Approved", "There is a problem with this photo"]
      when 'paused', 'paused_unapproved': ["Paused", "This photo is not being matched"]
      when 'removed': ["Removed", "This photo has been removed"]
      else ["", ""]
    end
  end

  def photo_set
    set = player.photos.approved - player.photos.select { |p| p.couple_combo_id.present? } - [self]
    set.unshift(self)
  end

  def combos
    Combo.find(:all, :conditions => ["(photo_one_id = ? OR photo_two_id = ?)", id, id], :include => [:photo_one, :photo_two])
  end

  def comboed_photo_ids
    Combo.find(:all, :conditions => ["(photo_one_id = ? OR photo_two_id = ?)", id, id]).collect{|c|c.other_photo_id(id)}.sort
  end

  def correlated_photo_ids(yes_threshold = 75, correlation_threshold = 75)
    ComboScore.correlations(id, yes_threshold, correlation_threshold).collect{|cs|cs.other_photo_id}
  end

  def partitioned_suggestions
    comboed_ids = comboed_photo_ids
    ComboScore.suggestions(id).partition{|suggested_id| comboed_ids.include?(suggested_id)}
  end

  def new_suggestions
    partitioned_suggestions.last
  end

  def new_suggestions_ordered
    new_suggestions.partition do |other_photo_id|
      Photo.find(other_photo_id).target_combos > 0
    end.flatten
  end

  def active_combos
    Combo.where(["active=true AND (photo_one_id = ? OR photo_two_id = ?)", id, id]).includes(:photo_one, :photo_two)
  end

  def active_combo_photos
    active_combos.collect { |c| [c.photo_one, c.photo_two] }.flatten.uniq.delete_if { |p| p == self }
  end

  def notify_admins
    Mailer.delay(:priority => 1).deliver_photo_upload_notification(self)
  end

  def generate_combos
    #TODO get rids of dups in PhotoPair.candidate_pairs_by_profile and point there
    if couple_combo_id.nil?
      PhotoPair.update_all_player_profile_stats(self.id)
      Combinator.delay(:priority => 3).restock_one(self)
    end
  end

  def combos_needed
    return 0 unless approved?
    total_combos = Combo.for_photo(id).where("creation_reason != 'otherphotomatch'").count
    active_combos_count = active_combos.count
    queued_count = photo_pairs.queued_for_response.length
    if total_combos < 20 || priority?
      2 - active_combos_count - [queued_count - target_combos, 0].max
    elsif total_combos < 40
      1 - active_combos_count - [queued_count - target_combos, 0].max
    elsif Time.new.mday % ((Time.new - created_at).to_f / (60*60*24*30).to_f).ceil == 0
      1 - active_combos_count - [queued_count - target_combos, 0].max
    else
      0
    end
  end

  def target_combos
    return 0 unless approved?
    base_target = bucket ? bucket + 1 : 3
    [base_target + activity_adjustment, 0].max
  end

  def deactivate_combos
    combos.each { |c| c.update_attribute(:active, false) }
  end

  def clear_reason
    self.rejected_reason = nil
  end

  def mail_rejection_reason
    Emailing.delay(:priority => 3).deliver("rejection_reason", player.user.id, self) unless player.user.nil?
  end

  def mail_approved
    Emailing.delay(:priority => 3).deliver("photo_approved", player.user.id, self) unless player.user.nil? || college_id.present?
  end

  def pausable?
    aasm_events_for_current_state.include?(:pause)
  end

  def resumable?
    aasm_events_for_current_state.include?(:resume)
  end

  def removable?
    aasm_events_for_current_state.include?(:remove)
  end

  def check_approved_count
    approved_count = player.photos.approved.count
    if approved_count == 1
      player.interests.map(&:save)
    elsif approved_count == 0
      player.interests.map(&:decrement_club_count)
    end
  end

  def crop!(params)
    return if params.blank? || params[:x].blank? || params[:y].blank? || params[:w].blank? || params[:h].blank?
    cropping? ? crop.update_attributes(params) : create_crop(params)
    if ENV['PROCESS_IN_BACKGROUND']
      image.clear_processed!
    else
      image.reprocess!
    end
  end

  def self.download_image(url)
    open(URI.parse(url))
  end

  def cropping?
    crop
  end

  def set_defaults
    self.gender = player.gender_with_unknown if gender.blank?
    self.same_sex = (player.same_sex  || false) if same_sex.blank?
    return true
  end

  def redundant_gender
    gender == "u" ? player.gender : gender
  end

  def self.create_new_user(photo_id, email)
    photo = Photo.find(photo_id)
    player = Player.create!(:gender => photo.gender, :connectable => false)
    user = player.create_user(:email => email, :password => "123456", :password_confirmation => "123456", :terms_of_service => true)
    photo.update_attribute(:player_id, player.id)
  end

  def ready_for_response
    photo_pairs.includes(:combo).ready_for_response.map(&:combo).sort_by{|c|c.response.revealed_at}.reverse
  end

  def other_side_matches
    photo_pairs.other_side_matches.map(&:other_photo)
  end

  def ready_to_connect
    connectable? ? Combo.matching_full.with_responses_for([self], [:good,:interested]).select { |combo| combo.status == :match && combo.other_photo(self).connectable? } : []
  end

  def confirmed_or_approved?
    confirmed? || approved?
  end

  def paused_states?
    paused? || paused_unapproved?
  end

  def priority?
    priority_until.present? && priority_until > Time.new
  end

  def to_param
    id.to_obfuscated
  end

  def check_max_approved_photos
    return true if current_state_was == 'approved'
    raise MaxPhotosException if player && player.photos.approved.count >= Features.max_photos_per_user
    return true
  end

  def check_age
    return true if current_state_was == 'approved' || player.nil?
    age = player.profile.age if player.profile.present? && player.profile.age.present?
    age = player.facebook_profile.age if age.nil? && player.facebook_profile.present?
    raise UnderAgeException if age && age < 18
    return true
  end

  def adjust_for_activity
    activity_adjustment = 0
    awaiting_count = ready_for_response.select { |c| c.response_state(@current_player) == 'unanswered' }.length
    last_login = user && (user.last_request_at || user.created_at)
    last_login_ago  = last_login ? (Date.today - last_login.to_date).to_i : 100
    if awaiting_count > 5 && last_login_ago > 14
      activity_adjustment -= (last_login_ago / 10)
      activity_adjustment -= (awaiting_count / 3)
    end
    update_attribute(:activity_adjustment, activity_adjustment)
    activity_adjustment
  end

  def bucket_or_default
    bucket || 3
  end

  def bucket_score(other_photo)
    return 0 if bucket.nil? || other_photo.bucket.nil?
    (bucket - other_photo.bucket).abs
  end

  def comboed_other_photo_ids
    connection.select_values("select photo_one_id from combos where photo_two_id = #{id} UNION select photo_two_id from combos where photo_one_id = #{id}")
  end
  
  def self.adjust_all_for_activity
    Rails.logger.info("adjust_all_for_activity")
    find(:all, :order => "id").collect do |photo|
      "#{photo.id}: #{photo.adjust_for_activity}"
    end
  end

  def self.notify_unconfirmed
    unconfirmed_photos = Photo.unconfirmed.where("created_at BETWEEN ? and ?", 2.days.ago, 1.day.ago)
    unconfirmed_photos.each do |photo|
      Emailing.delay(:priority => 3).deliver("notify_unconfirmed", photo.player.user.id, photo.id)
    end
  end

  class Helper
    include ActionView::Helpers::DateHelper
  end

  def self.report
    helper = Helper.new
    all_photos = find(:all, :order => "id", :conditions => "current_state = 'approved'")
    all_photos.collect do |photo|
      responses = photo.combos.map{|c|c.response_state(photo.player)}
      good_count = responses.count{|response|["good", "interested", "uninterested"].include?(response)}
      bad_count = responses.count{|response|["bad"].include?(response)}
      r = {:id => photo.id,
           :last_login => photo.player.nil? || photo.user.nil? ? "No User" : (photo.user.last_request_at.nil? ? "No Requests" : helper.time_ago_in_words(photo.user.last_request_at)),
           :age => helper.time_ago_in_words(photo.created_at),
           :state => photo.current_state,
           :awaiting_count => photo.ready_for_response.count,
           :good_count => good_count,
           :bad_count => bad_count,
           :adjust_for_activity => photo.activity_adjustment,
           :target_combos => photo.target_combos,
           :bucket => photo.bucket}
      p r
      r
    end
  end

  def self.admin_find(param)
    find(param.to_i == 0 ? Integer.unobfuscate(param) : param)
  end
end
