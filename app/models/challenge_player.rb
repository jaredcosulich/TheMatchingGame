class ChallengePlayer < ActiveRecord::Base
  belongs_to :player
  belongs_to :challenge
  has_one :game
  has_many :answers, :through => :game

  validates :email, :presence => true, :email => true
  validates :name, :presence => true

  before_validation :connect_to_existing_player, :on => :create
  before_create :generate_token
  after_create :send_invitation
  after_destroy :check_completed_on_destroy

  scope :ranked, order("correct_count desc, id desc")
  scope :full, includes([:player, {:answers => {:combo => [:response, :photo_one, :photo_two]}}])

  def check_completed
    update_cache
    if challenge_completed?
      notify_challenge_game_complete unless challenge.check_completed
      true
    end
  end

  def check_completed_on_destroy
    challenge.check_completed
  end

  def update_cache
    self.correct_count = (game.answers.correct.map(&:combo) & challenge.combos).length
    if (answers.map(&:combo) & challenge.combos).length == challenge.combos.length
      self.completed_at = Time.new
    end
    save
  end

  def challenge_completed?
    completed_at.present?
  end

  def challenge_answers
    challenge_combos = challenge.challenge_combos.with_combo.map(&:combo)
    answers.select{|a|challenge_combos.include?(a.combo)}
  end

  def notify_challenge_game_complete
    Mailer.delay(:priority => 5).deliver_challenge_player_completed(self.id)
  end

  def answer_for(combo)
    answers.detect { |a| a.combo == combo }
  end

  def send_invitation
    role = player == challenge.creator ? "creator" : "player"
    Mailer.delay(:priority => 1).send("deliver_challenge_#{role}_invitation".to_sym, self.id)
  end

  def generate_token
    self.token = UUID.generate(:compact)
  end

  def seen_combo_ids
    return [] if player.nil?
    player.challenges.collect { |c| c.challenge_combos.map(&:combo_id) }
  end

  def find_or_create_player(current_player = Player.new)
    if existing_user = User.find_by_email(email)
      update_attribute(:player, existing_user.player)
      existing_user.player
    else
      player = current_player.email.present? ? Player.new : current_player
      User.create_email_user(player, email)
      update_attribute(:player, player.reload)
      player
    end
  end

  def connect_to_existing_player
    existing_user = User.find_by_email(email)
    self.player = existing_user.player if existing_user
  end
end
