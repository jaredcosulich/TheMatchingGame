class Game < ActiveRecord::Base
  belongs_to :player
  has_many :answers, :dependent => :destroy
  belongs_to :challenge_player

  before_create :set_player_from_challenge_player

  scope :recent, includes({:answers => {:combo => [:photo_one, :photo_two]}}).where("answers.id is not null").order("games.created_at desc")

  class TooFewCombos < StandardError
    attr_accessor :combo_count, :player_id, :player_answer_count
    def initialize(combo_count, player)
      @combo_count = combo_count
      @player_id = player.id
      @player_answer_count = player.answers.count
    end
    
    def to_hash
      {:action => "Game.combos",
       :error_message => "Game.combos made #{combo_count} for player #{player_id} with #{player_answer_count} answers",
       :combo_count => combo_count,
       :player_id => player_id,
       :player_answer_count => player_answer_count,
       }
    end
  end


  def combo_conditions(excluded_combo_ids)
    interested_player_ids = player.photos.empty? ? [] : Combo.with_interested(player.photos).collect { |combo| combo.other_actor(player).id }
    excluded_combo_conditions = excluded_combo_ids.empty? ? nil : "combos.id not in (#{excluded_combo_ids.join(',')}) and "
    excluded_player_ids = (interested_player_ids + [player.id]).join(',')
    player.new_record? ? nil : ["#{excluded_combo_conditions}photos.player_id not in (#{excluded_player_ids}) AND photo_twos_combos.player_id  not in (#{excluded_player_ids})"]
  end

  def predicted_combos_for_challenge(count, excluded_combo_ids)
    conditions = combo_conditions(excluded_combo_ids)

    combo_set = ComboSet.new(count)
    combo_set.add(count * 0.75) {Combo.trending_yes.active_random.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}
    combo_set.add(count * 0.5) {Combo.trending.active_random.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}
    combo_set.add(count * 0.5) {Combo.few_votes.active_random.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}
    combo_set.add(count)       {Combo.active_recent.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}
    combo_set.add(count)       {Combo.active_random.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}

    HoptoadNotifier.notify(TooFewCombos.new(combo_set.length, player)) unless combo_set.full?

    combo_set.combos.shuffle

  end

  def college_combos(count, excluded_combo_ids=[])
    conditions = combo_conditions(excluded_combo_ids)

    combo_set = ComboSet.new(count)

    college_id = player.college_id

    verified_count = (count / 3)
    rand_good = rand(verified_count - 1).ceil + 1
    combo_ids = Response.good.not_seen(player).select("responses.combo_id").random.limit(100).map(&:combo_id)
    combo_set.add(rand_good)                  {Combo.not_college.good_training_efficient(combo_ids).full.find(:all, :conditions => conditions, :limit => 10)} unless combo_ids.blank?
    bad_combo_ids = Response.bad.not_seen(player).select("responses.combo_id").random.limit(100).map(&:combo_id)
    combo_set.add(verified_count - rand_good) {Combo.not_college.bad_training_efficient(bad_combo_ids).full.find(:all, :conditions => conditions, :limit => 10)} unless bad_combo_ids.blank?

    combo_set.add(count * 0.4)                {Combo.college(college_id).trending_yes.active_random.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}
    combo_set.add(count * 0.3)                {Combo.college(college_id).few_votes.active_random.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}
    combo_set.add(count * 0.3)                {Combo.college(college_id).old.active.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}
    combo_set.add(count)                      {Combo.college(college_id).active_random.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}

    combo_set.add(count * 0.4)                {Combo.not_coupled.trending_yes.active_random.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}
    combo_set.add(count * 0.3)                {Combo.not_coupled.few_votes.active_random.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}
    combo_set.add(count * 0.3)                {Combo.not_coupled.old.active.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}
    combo_set.add(count)                      {Combo.not_coupled.active_random.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}

    HoptoadNotifier.notify(TooFewCombos.new(combo_set.length, player)) unless combo_set.full?

    combos = combo_set.combos.shuffle

    combos = combos.sort { |a,b| a.verified? ? 1 : -1 <=> b.verified? ? 1 : -1 }
    verified_count = combos.select{ |c| c.verified? }.length
    if verified_count > 0
      verified_every = (combos.length.to_f / verified_count.to_f).ceil
      verified_count.times do |i|
        last_verified_index = combos.length - 1 - combos.reverse.index(combos.reverse.detect{ |c| c.verified? })
        last_verified = combos.slice!(last_verified_index)
        next_verified_position = (verified_every * (i + 1) - 1)
        combos.insert(next_verified_position, last_verified) if combos.length < 4 || next_verified_position != combos.length
      end
    end
    combos.compact
  end

  def combos(count, excluded_combo_ids=[])
    conditions = combo_conditions(excluded_combo_ids)

    verified_count = (count / 3)

    combo_set = ComboSet.new(count)
    if player.photos.detect { |p| p.couple_combo_id.present? }.nil?
      combo_set.add(count * 0.1)         {Combo.active_coupled.not_seen(player).random.full.find(:all, :conditions => conditions, :limit => 10)}
      verified_count -= 1 if combo_set.length > 0
    end

    rand_good = rand(verified_count - 1).ceil + 1
    if player.level == 1
      combo_set.add(count * 0.3)              {Combo.trending_yes.active_random.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}
    end
    if player.games.count < 10
      combo_set.add(rand_good)                {Combo.good_training.not_fake_predicted.random.not_seen(player).easy_good(player.good_training_yes_count_threshold).full.find(:all, :conditions => conditions, :limit => 10)}
    else
      combo_ids = Response.good.not_seen(player).select("responses.combo_id").random.limit(100).map(&:combo_id)
      combo_set.add(rand_good)                {Combo.good_training_efficient(combo_ids).full.find(:all, :conditions => conditions, :limit => 10)} unless combo_ids.blank?
    end
    bad_combo_ids = Response.bad.not_seen(player).select("responses.combo_id").random.limit(100).map(&:combo_id)
    combo_set.add(verified_count - rand_good) {Combo.bad_training_efficient(bad_combo_ids).full.find(:all, :conditions => conditions, :limit => 10)} unless bad_combo_ids.blank?
    combo_set.add(1)                          {Combo.priority.active_random.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}

    few_vote_count = player.level > 1 ? count : count * 0.3
    combo_set.add(few_vote_count)             {Combo.few_votes.active_random.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}
    combo_set.add(count * 0.3)                {Combo.old.active.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}
    combo_set.add(count)                      {Combo.active_random.not_seen(player).full.find(:all, :conditions => conditions, :limit => count * 2)}
    combo_set.add(count)                      {Combo.not_coupled.not_seen(player).responded_to.random.full.find(:all, :conditions => conditions, :limit => count * 2)}

    HoptoadNotifier.notify(TooFewCombos.new(combo_set.length, player)) unless combo_set.full?

    combos = combo_set.combos.shuffle

    combos = combos.sort { |a,b| a.verified? ? 1 : -1 <=> b.verified? ? 1 : -1 }
    verified_count = combos.select{ |c| c.verified? }.length
    if verified_count > 0
      verified_every = (combos.length / verified_count)
      verified_count.times do |i|
        last_verified_index = combos.length - 1 - combos.reverse.index(combos.reverse.detect{ |c| c.verified? })
        last_verified = combos.slice!(last_verified_index)
        next_verified_position = (verified_every * (i + 1) - 1)
        combos.insert(next_verified_position, last_verified) if combos.length < 4 || next_verified_position != combos.length
      end
    end

    if player.games.count < 4
      fake_predicted = Combo.fake_predicted(combos).full.random.where(conditions).limit(2)

      if fake_predicted[0].present?
        combos.delete_at(1)
        combos.insert(1, fake_predicted[0])
      end

      if fake_predicted[1].present?
        combos.delete_at(6)
        combos.insert(6, fake_predicted[1])
      end
    end

    combos
  end

  def check_completed
    return challenge_player.check_completed if challenge_player_id.present? && challenge_player.present?
  end

  def scored_at
    created_at
  end

  def self.stats(number)
    unanimous_stats = {0=>0,1=>0,2=>0,3=>0,4=>0,5=>0,6=>0,7=>0}
    number.times do
      candidates = Game.new(:player => Player.new).combos(7)
      unanimous_count = candidates.select{ |c| c.unanimous? }.length
      pp unanimous_count
      unanimous_stats[unanimous_count] += 1
    end
    return unanimous_stats
  end

  def set_player_from_challenge_player
    self.player_id = challenge_player.player_id if challenge_player.present?
  end
end
