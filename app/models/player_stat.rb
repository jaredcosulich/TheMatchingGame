class PlayerStat < ActiveRecord::Base
  belongs_to :player

  before_save :calculate

  class AnswerWeight
    attr_accessor :answer_count, :correct_count, :incorrect_count
    def initialize(correct_count = 0, incorrect_count = 0, answer_count = 0)
      @correct_count = correct_count
      @incorrect_count = incorrect_count
      @answer_count = answer_count
    end

    def <<(answer)
      @answer_count += 1
      @correct_count += 1 if answer.correct?
      @incorrect_count += 1 if answer.incorrect?
    end

    def accuracy
      verified_count = @correct_count + @incorrect_count
      (100.0 * @correct_count.to_f / verified_count.to_f) if verified_count > 0
    end

    def value
      AnswerWeight.calculate(accuracy, @answer_count)
    end

    def point_value
      (value * 1000).to_i - 1000 if value
    end

    def self.experience_multiplier(answer_count)
      [(Math.log((answer_count  + 25)/ 3.87)/Math.log(4) - (Math.log(25)/Math.log(4))) + 2, 1].max
    end

    def self.calculate(accuracy, answer_count)
      return 1 if accuracy.nil?
      experience_weight = experience_multiplier(answer_count)
      (Math.sqrt(experience_weight) ** [((accuracy.to_f - 41.6)/20.8), 2.0].min).to_f
    end
  end

  class ScoreHistory
    attr_accessor :history
    def initialize(player)
      @history = [GameEvent.new(Game.new(:created_at => 1000.years.ago))]

      player.games.find(:all, :order => "created_at asc", :include => [:answers => {:combo => :response}]).collect do |g|
        @history << GameEvent.new(g)

        g.answers.each { |a| (@history << ResponseEvent.new(a, a.combo.response)) if a.combo.verified? && !(a.existing_correct? || a.existing_incorrect?)}
      end
      @history.sort!

      aw = AnswerWeight.new
      @history.each do |score_event|
        score_event.record(aw)
        score_event.score = aw.point_value
      end
    end

  end

  class ScoreEvent < Struct.new(:scoring_object, :title, :score, :date)
    def initialize(object)
      self.scoring_object = object
      self.date = scoring_object.scored_at
      self.title = scoring_object.class.name
    end

    def <=>(other)
      date <=> other.date
    end
  end

  class GameEvent < ScoreEvent
    def record(aw)
      scoring_object.answers.each do |a|
        aw.answer_count += 1
        aw.correct_count += 1 if a.existing_correct?
        aw.incorrect_count += 1 if a.existing_incorrect?
      end
    end
  end

  class ResponseEvent < ScoreEvent
    def initialize(answer, response)
      super(response)
      @answer = answer
    end

    def record(aw)
      aw.correct_count += 1 if @answer.correct?
      aw.incorrect_count += 1 if @answer.incorrect?
    end
  end

  def score_history
    ScoreHistory.new(player).history
  end

  def points
    (answer_weight * 1000).to_i - 1000 if answer_weight
  end

  def percentile(attr_name, experience_level=false)
    attr_value = send(attr_name)
    return nil if attr_value.nil?
    experience_level_conditions = " and answer_count BETWEEN #{answer_count / 2} AND #{answer_count * 2}"
    100 * PlayerStat.count(:conditions => "game_count > 1 AND #{attr_name} < #{attr_value}#{experience_level_conditions if experience_level}") / PlayerStat.count(:conditions => "game_count > 1 AND #{attr_name} is not null#{experience_level_conditions if experience_level}")
  end

  def calculate
    self.game_count      = player.games.count
    self.answer_count    = player.answers.count
    self.yes_count       = player.answers.yes.count
    self.no_count        = player.answers.no.count
    self.correct_count   = player.answers.correct.not_fake_predicted.count
    self.incorrect_count = player.answers.incorrect.not_fake_predicted.count
    calculated_accuracy = (correct_count + incorrect_count) > 0 ? (100.0 * correct_count.to_f / (correct_count + incorrect_count).to_f) : nil
    self.accuracy = calculated_accuracy
    self.yes_percent = 100 * yes_count / answer_count if answer_count > 0
    self.answer_weight = PlayerStat::AnswerWeight.calculate(calculated_accuracy, answer_count)
  end

  def self.recalculate
    t = Time.new
    PlayerStat.find_in_batches(:batch_size => 100, :conditions => "accuracy is not null", :include => :player) do |player_stats|
      PlayerStat.transaction do
        player_stats.each { |player_stat| player_stat.save! }
      end
    end
    "Done in #{Time.new - t}"
  end
end
