class Combinator
  def self.restock_one(photo)
    if (needed_count = photo.combos_needed) > 0
#      PhotoPair.create_and_update_candidate_pairs_by_correlation(photo, 20)

      new_combos = new_combos(photo, needed_count)
      new_combos[0...needed_count].each{|combo|combo.save}
    end
  end

  def self.restock_all
    time = Time.new
    timings = {}
    disabled = []
    needed_combos = []
    really_needed_combos = []
    added = []
    #Photo.adjust_all_for_activity
#    timings[:update_all_connection_scores] = Benchmark.realtime{PhotoPair.update_all_connection_scores}
    disabled = Combo.where("inactivated_at > ?", 1.hour.ago)

    timings[:needed_combos] = Benchmark.realtime do
      needed_combos = Photo.need_combos
    end
    timings[:really_needed_combos] = Benchmark.realtime do
      really_needed_combos = needed_combos.select { |photo| photo.combos_needed > 0 }
    end
    timings[:restocking] = Benchmark.realtime do
      added = really_needed_combos.map { |photo| restock_one(photo) }.flatten.compact
    end

#    Mailer.restock_report(disabled, added, Time.new - time, timings).deliver
  end

  def self.new_combos(photo, limit)
    Rails.logger.info("new_combos for #{photo.id}, limit #{limit}")

    combos = PhotoPair.candidate_pairs_by_similar_photos(photo, limit).collect do |pair|
      Combo.new(:photo_one_id => photo.id, :photo_two_id => pair.other_photo_id, :photo_one_pair => pair, :creation_reason => "similar2", :college => pair.college)
    end

    if combos.length < limit
      Rails.logger.info("looking for #{limit - combos.length} profile + match me combos")
      combos += PhotoPair.candidate_pairs_by_profile_and_match_me(photo, limit - combos.length).collect do |pair|
        Combo.new(:photo_one_id => photo.id, :photo_two_id => pair.other_photo_id, :photo_one_pair => pair, :creation_reason => "mme+profile", :college => pair.college)
      end
    end

    if combos.length < limit
      Rails.logger.info("looking for #{limit - combos.length} profile combos")
      combos += PhotoPair.candidate_pairs_by_profile(photo, limit - combos.length, photo.comboed_other_photo_ids).collect do |pair|
        Combo.new(:photo_one_id => photo.id, :photo_two_id => pair.other_photo_id, :photo_one_pair => pair, :creation_reason => "profile", :college => pair.college)
      end
    end
    combos
  end

end
