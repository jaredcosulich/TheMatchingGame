class User < ActiveRecord::Base
  include ActiveModel::Validations

  STARTING_CREDITS = 0
  
  acts_as_authentic do |auth_config|
    auth_config.validate_email_field = false

    auth_config.ignore_blank_passwords = true
  end

  acts_as_mappable :distance_field_name => :distance,
                   :lat_column_name => :location_lat,
                   :lng_column_name => :location_lng

  belongs_to :player
  has_one :email_preference
  delegate :awaiting_response, :prediction_progress, :to => :email_preference, :allow_nil => true
  has_many :social_gold_transactions
  has_many :transactions
  has_many :emailings
  has_many :want_payments
  accepts_nested_attributes_for :email_preference

  validates_acceptance_of :terms_of_service, :allow_nil => false, :accept => true
  validates :email, :presence => true, :email => true, :uniqueness => {:case_sensitive => false}

  after_create :create_email_preference

  default_scope where("deleted_at is null")

  scope :emailable, lambda { |preference_name|
    includes([:email_preference, {:player => :photos}]).
      where("email not like 'fb_%thematchinggame.com' AND email_preferences.#{preference_name} = true").
      order("users.id asc")
  }

  scope :fb_email, where("email like 'fb_%thematchinggame.com'").order("created_at desc")

  def email_from_fb_info
    fb_info = player.try(:facebook_profile).try(:fb_info)
    if fb_info && email_from_fb = JSON.parse(fb_info)["email"]
      email_from_fb
    end
  end

  def self.fix_fb_emails
    fixed_player_ids = (User.fb_email.collect { |u| u.player.merge_duplicate_users } || []).compact.collect { |u| u.player_id }
    User.fb_email.each do |u|
      if actual_email = u.email_from_fb_info
        fixed_player_ids << u.player_id if u.update_attributes(:email => actual_email)
      end
    end
    Mailer.delay(:priority => 9).deliver_admin_notification(:subject => "Fixed FB Emails", :fixed_player_ids => fixed_player_ids) unless fixed_player_ids.blank?
  end

  def self.find_or_create_fb(player_id, fb_id)
    return nil if fb_id.nil?
    user = User.find_by_fb_id(fb_id)
    return user if user
    player = Player.find_by_id(player_id) || Player.new
    player = Player.new unless player.fb_id.blank? || player.fb_id == fb_id
    User.find(create_email_user(player, "fb_#{fb_id}@thematchinggame.com", fb_id).id, :include => :player)
  end

  def self.create_email_user(player, email, fb_id=nil)
    User.create(
      :fb_id => fb_id,
      :email => email,
      :password => uuid = UUID.generate,
      :password_confirmation => uuid,
      :player => player,
      :terms_of_service => "1"
    )
  end

  def admin?
    fb_id == 580888580 || fb_id == 15700 || fb_id == 1509059
  end

  def blank_email?
    email.blank? || email =~ /fb_\w+@thematchinggame.com/
  end

  def update_credits(amount)
    self.credits = credits + amount
    raise InsufficientCredits if credits < 0
    save!
  end

  def credits
    read_attribute(:credits) || 0
  end

  def sufficient_credits?
    credits >= ComboAction::CREDITS_TO_CONNECT
  end

  def subscribed?
    subscribed_until.present? && subscribed_until > Time.now
  end

  def check_subscription
    now = Time.now.to_i
    raw_signature = SocialGoldTransaction.canonicalize("action" => "status", "ts" => now, "subscription_offer_id" => SOCIAL_GOLD_OPTIONS[:subscription_offer], "user_id" => id) + SOCIAL_GOLD_OPTIONS[:secret_key]
    signature = Digest::MD5.hexdigest(raw_signature)

    uri = URI.parse("https://#{::SOCIAL_GOLD_OPTIONS[:server]}/socialgold/subscription/v1/#{SOCIAL_GOLD_OPTIONS[:subscription_offer]}/#{id}/status?ts=#{now}&sig=#{signature}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    status = JSON.parse(response.body)
  end

  def give_default_credits
    transactions.create!(:source => self, :amount => STARTING_CREDITS)
  end

  def needs_to_pay?
    return false if (last_payment.blank? && created_at > 1.week.ago.to_date)
    last_payment.blank? || last_payment < 1.month.ago.to_date
  end

end
