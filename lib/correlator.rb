class Correlator
  cattr_accessor :vote_threshold
  self.vote_threshold = 3

  def initialize
    @suggestion_maps = {}
    @correlation_maps = {}
    @combo_map = Hash.new{|h,k| h[k]=[]}
    @combo_chains = Hash.new{|h,k| h[k]=[]}
    @approved_photo_ids = {}

    Combo.find(:all, :include => [:photo_one, :photo_two]).each do |combo|
      @combo_map[combo.photo_one_id] << combo
      @combo_map[combo.photo_two_id] << combo
      @approved_photo_ids[combo.photo_one_id] = true if combo.photo_one.approved? && combo.photo_one.couple_combo_id.nil?
      @approved_photo_ids[combo.photo_two_id] = true if combo.photo_two.approved? && combo.photo_one.couple_combo_id.nil?
    end

    @combo_map.each_pair do | photo_id, level_1_combos |
      level_1_combos.each do |level_1_combo|
        @combo_map[level_1_combo.other_photo_id(photo_id)].each do |level_2_combo|
          @combo_chains[photo_id] << [level_1_combo, level_2_combo]
        end
      end
    end
  end

  def inspect
    "Correlator for #{@combo_map.length} photos"
  end

  def combos
    @combo_map
  end

  def find_combo(photo_id, other_photo_id)
    combos[photo_id].detect { |c| c.photo_ids.include?(other_photo_id) }
  end

  def correlations(correlations_threshold=75)
    return @correlation_maps[correlations_threshold] if @correlation_maps[correlations_threshold]
    correlation_map = @correlation_maps[correlations_threshold] = Hash.new{|h,k| h[k]=Hash.new{|h,k| h[k]=[]}}
    @combo_chains.each_pair do |photo_id, chains|
      chains.each do |chain|
        level_1_combo = chain[0]
        level_2_combo = chain[1]
        next if level_1_combo.total_votes <= vote_threshold || level_2_combo.total_votes <= vote_threshold
        chain_score = (level_1_combo.yes_percent * (level_2_combo.yes_percent * level_1_combo.yes_percent) / 100) / 100
        level_2_photo_id = level_2_combo.other_photo_id(level_1_combo.other_photo_id(photo_id))
        correlation_map[photo_id][level_2_photo_id] << chain_score if chain_score >= correlations_threshold
      end
    end

    correlation_map.each_pair do |photo_id, correlated_photos|
      correlated_photos.each_pair do |other_photo_id, scores|
        average_score = scores.inject(0) { |sum, score| sum += score } / scores.length
        correlation_map[photo_id][other_photo_id] = average_score
      end
    end

    correlation_map
  end

  def suggestions(yes_threshold, correlations_threshold)
    return @suggestion_maps[yes_threshold] if @suggestion_maps[yes_threshold]
    suggestion_map = @suggestion_maps[yes_threshold] = Hash.new{|h,k| h[k]=[]}
    correlations(correlations_threshold).each_pair do |photo_id, correlations|
      next unless @approved_photo_ids[photo_id]
      correlations.keys.each do |level_2_photo_id|
        combos = @combo_chains[level_2_photo_id].collect { |chain| chain[0] }
        suggestion_map[photo_id] << combos.select do |combo|
          (combo.yes_count + combo.no_count > vote_threshold) &&
          combo.yes_percent >= yes_threshold
        end.collect { |combo| combo.other_photo_id(level_2_photo_id) }.select { |level_3_photo_id| @approved_photo_ids[level_3_photo_id] }
      end
    end

    suggestion_map.values.each { |v| v.flatten!.uniq! }

    suggestion_map
  end

  def existing_suggestions(yes_threshold=75, correlations_threshold=75)
    existing = Hash.new{|h,k| h[k]=[]}
    suggestions(yes_threshold, correlations_threshold).each_pair do |photo_id, suggested_photo_ids|
      existing[photo_id] = suggested_photo_ids.select { |id| !find_combo(photo_id, id).nil? }
    end
    existing
  end

  def not_existing_suggestions(yes_threshold=75, correlations_threshold=75)
    not_existing = Hash.new{|h,k| h[k]=[]}
    suggestions(yes_threshold, correlations_threshold).each_pair do |photo_id, suggested_photo_ids|
      not_existing[photo_id] = suggested_photo_ids.select { |id| find_combo(photo_id, id).nil? }
    end
    not_existing
  end
end
