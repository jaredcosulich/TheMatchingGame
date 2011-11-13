class Challenge < ActiveRecord::Base
  belongs_to :creator, :class_name => "Player"
  validates_presence_of :creator
  validates_presence_of :name
  before_validation :add_creator_as_player, :on => :create

  has_many :challenge_players
  validates_associated :challenge_players
  validates_presence_of :challenge_players
  accepts_nested_attributes_for :challenge_players, :reject_if => proc { |attributes| attributes.reject { |k, v| k == '_delete' }.all? { |k, v| v.blank? } }

  has_many :challenge_combos
  has_many :combos, :through => :challenge_combos

  before_create :select_challenge_combos

  def initialize(params={})
    super(params)
    if creator.present?
      self.name = (creator.first_name.present? ? "#{creator.first_name}'s Challenge" : "Matching Challenge") if name.blank? 
      self.invitation_text = default_invitation_text if invitation_text.blank?
    end
  end

  def check_completed
    unless challenge_players.collect{|c|c.challenge_completed?}.include?(false)
      notify_challenge_completed
      true
    end
  end

  def notify_challenge_completed
    challenge_players.each { |cp| Emailing.delay(:priority => 3).deliver("challenge_complete", cp.player.user.id, cp.id) }
  end

  def combo_conditions
    conditions = "true"

    excluded_player_ids = challenge_players.map(& :player_id).compact.join(",")
    conditions += " and photos.player_id not in (#{excluded_player_ids}) and photo_twos_combos.player_id not in (#{excluded_player_ids})" unless excluded_player_ids.empty?

    already_seen_combo_ids = challenge_players.collect { |cp| cp.seen_combo_ids }.flatten.uniq
    conditions += " and combos.id not in (#{already_seen_combo_ids.join(',')})" unless already_seen_combo_ids.blank?
    conditions
  end

  def select_challenge_combos
    conditions = combo_conditions

    combo_set = ComboSet.new(challenge_combo_count = Features.challenge_scoring_combos_to_show)
    combo_set.add(challenge_combo_count * 0.60) {Combo.not_coupled.good_training.random.full.find(:all, :conditions => conditions, :limit => challenge_combo_count * 2)}
    combo_set.add(challenge_combo_count * 0.40) {Combo.bad_training.random.full.find(:all, :conditions => conditions, :limit => challenge_combo_count * 2)}

    combo_set.combos.shuffle.collect do |combo|
      challenge_combos.build(:combo => combo)
    end
  end

  def winners
    return [] unless completed?
    ranked = challenge_players.ranked.all
    winning_correct_count = ranked.first.correct_count
    ranked.select{|cp|cp.correct_count == winning_correct_count}
  end

  def completed?
    challenge_players.detect {|cp| cp.completed_at.nil? }.nil?
  end

  def completed_at
    completed_ats = challenge_players.collect(&:completed_at)
    completed_ats.include?(nil) ? nil : completed_ats.max
  end

  def challenge_player_for(player)
    challenge_players.detect { |p| p.player_id == player.id }
  end

  def add_creator_as_player
    if creator_challenge_player = challenge_players.first
      User.create_email_user(creator, creator_challenge_player.email) if creator.email.blank?
      creator.create_profile(:first_name => creator_challenge_player.name) if creator.profile.blank?
    end
  end

  def combos_with_predicted(game)
    predicted = game.predicted_combos_for_challenge(Features.challenge_predicted_combos_to_show - game.answers.predicted.length, challenge_combos.map(&:combo_id))
    challenge_not_yet_answered = challenge_combos.full.map(&:combo) - game.answers.map(&:combo)
    total_combos_length = (predicted.length + challenge_not_yet_answered.length)
    game_combos = [challenge_not_yet_answered.shift]
    while game_combos.length < total_combos_length do
      game_combos << [predicted, challenge_not_yet_answered].choice.shift
      game_combos.compact!
    end
    game_combos.compact
  end

  def default_invitation_text
    <<text
Hi,

You've been challenged by #{creator.full_name} to see which of you is a better match maker!

Are you up to the challenge?
text
  end

  def to_param
    id.to_obfuscated
  end

end
