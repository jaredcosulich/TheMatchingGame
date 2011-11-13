class ComboScore < ActiveRecord::Base
  belongs_to :combo

  scope :connections, lambda { |photo_id, threshold|
    {
        :conditions => ["photo_id = ? AND #{ComboScore.score_to_use_method} >= ? AND vote_count > ? AND (response is null or response >= 0) ", photo_id, threshold, 3]
    }
  }

  scope :negative_connections, lambda { |photo_id, threshold|
    {
        :conditions => ["photo_id = ? AND #{ComboScore.score_to_use_method} <= ? AND vote_count > ?", photo_id, threshold, 3]
    }
  }

  def self.create_or_update_for_combo(combo, player_weights = {})
    scores = ComboScore.find(:all, :conditions => ["combo_id = ?", combo.id])
    if scores.empty?
      ComboScore.new(combo, :photo_one).save!
      ComboScore.new(combo, :photo_two).save!
    else
      scores.each do |combo_score|
        combo_score.update_attributes(combo_score.calculate_attrs(combo, combo_score.photo_id == combo.photo_one_id ? :photo_one : :photo_two, player_weights))
      end
    end
  end

  def initialize(combo, position)
    super(calculate_attrs(combo, position))
  end

  def calculate_attrs(combo, position, player_weights = {})
    photo_id = combo.send("#{position}_id")
    other_photo_id = combo.other_photo_id(photo_id)
    other_position = position == :photo_one ? :photo_two : :photo_one
    answer = combo.send("#{position}_answer")
    other_answer = combo.send("#{other_position}_answer")
    {
      :photo_id => photo_id,
      :combo_id => combo.id,
      :yes_count => combo.yes_count,
      :no_count => combo.no_count,
      :vote_count => combo.yes_count + combo.no_count,
      :yes_percent => combo.yes_percent,
      :active => combo.active?,
      :response => response_score(answer),
      :other_photo_id => other_photo_id,
      :other_photo_approved => combo.send(other_position).approved?,
      :other_response => response_score(other_answer),
      :score => weighted_score(combo, player_weights)
    }
  end

  def weighted_score(combo, player_weights)
    weighted_count = 0.0
    weighted_yes_count = 0.0
    combo.answers.each do |answer|
      weight = if answer.game.nil?
        1
      else
        if player_weights.empty?
          stat = PlayerStat.find_by_player_id(answer.game.player_id)
          stat.nil? ? 1 : stat.answer_weight
        else
          player_weights[answer.game.player_id] || 1
        end
      end
      weighted_count += weight
      weighted_yes_count += weight if answer.answer =~ /y/
    end
    weighted_yes_count * 100 / weighted_count
  end

  def response_score(answer)
    case answer
      when 'good', 'uninterested' :
        1
      when 'interested' :
        2
      when 'bad' :
        -1
      else
        0
    end
  end

  def score_to_use
    send(ComboScore.score_to_use_method)
  end

  def self.score_to_use_method
    :score
  end

  def self.generate_all
    t = Time.new
    player_weights = PlayerStat.all.inject({}) do |weights, stat|
      weights[stat.player_id] = stat.answer_weight  
      weights
    end

    Combo.find_in_batches(:batch_size => 100, :include => [{:answers => :game}, :response, :photo_one, :photo_two]) do |combos|
      Combo.transaction do
        combos.each do |combo|
          if combo.valid?
            ComboScore.create_or_update_for_combo(combo, player_weights)
          else
            ComboScore.destroy_all(['combo_id= ?', combo.id])
          end
        end
      end
    end
    "Generated #{ComboScore.count} in #{Time.new - t}"
  end

  def self.correlations(photo_id, yes_threshold, correlation_threshold)
    first_level = connections(photo_id, yes_threshold)
    scores = Hash.new{|h,k| h[k]=[]}
    first_level.collect do |score|
      connections(score.other_photo_id, yes_threshold).select do |second_level_score|
        correlation_score = score.score_to_use * score.score_to_use * second_level_score.score_to_use / 100 / 100
        scores[second_level_score.other_photo_id] << correlation_score
        correlation_score >= correlation_threshold
      end
    end.flatten.uniq
  end

  def self.negative_correlations(photo_id, yes_threshold = 75, correlation_threshold = 75)
    first_level_positive = connections(photo_id, yes_threshold)
    first_level_negative = negative_connections(photo_id, 100 - yes_threshold)

    scores = Hash.new{|h,k| h[k]=[]}

    pos_neg = first_level_positive.collect do |score|
      negative_connections(score.other_photo_id, 100 - yes_threshold).select do |second_level_score|
        correlation_score = (score.score_to_use) * (score.score_to_use) * (100 - second_level_score.score_to_use) / 100 / 100
        scores[second_level_score.other_photo_id] << correlation_score
        correlation_score >= correlation_threshold
      end
    end.flatten.uniq

    neg_pos = first_level_negative.collect do |score|
      connections(score.other_photo_id, yes_threshold).select do |second_level_score|
        correlation_score = (100 - score.score_to_use) * (100 - score.score_to_use) * second_level_score.score_to_use / 100 / 100
        scores[second_level_score.other_photo_id] << correlation_score
        correlation_score >= correlation_threshold
      end
    end.flatten.uniq

    scores.collect { |other_photo_id, scores| [other_photo_id, (scores.inject(0) { |total, score| total + score } / scores.length)] }.sort { |a,b| b[1] <=> a[1] }.collect{|a|a.first} 
  end

  def self.suggestions(photo_id, yes_threshold = 75, correlation_threshold = 75)
    second_level = correlations(photo_id, yes_threshold, correlation_threshold)
    second_level.collect { |combo_score| connections(combo_score.other_photo_id, yes_threshold).select{|cs|cs.other_photo_approved?} }.flatten.map(& :other_photo_id).uniq.sort
  end

  def self.regression_test
    correlator = Correlator.new
    suggestions = correlator.suggestions(75, 75)

    suggestions.keys.sort.each do |k|
      s = suggestions[k].sort
      cs = ComboScore.suggestions(k)
      unless s == cs
        puts "REGRESSION for #{k}"
        p "old correlator: #{s.inspect}"
        p "new correlator: #{cs.inspect}"
        unless (surplus = (cs - s)).empty?
          puts "SURPLUS: #{surplus.inspect} for #{k}"
        end
        unless (missing = (s - cs)).empty?
          puts "MISSING: #{missing.inspect} for #{k}"
        end
        puts
      end
    end

    Photo.all.each do |p|
      if (s = ComboScore.suggestions(p.id)).length > 0
        unless suggestions[p.id]
          puts "SURPLUS: #{s.inspect} for #{p.id}"
        end
      end
    end

    "Compared #{suggestions.length} suggestions"
  end
end
