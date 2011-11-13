class PhotoPair < ActiveRecord::Base
  belongs_to :photo
  belongs_to :other_photo, :class_name => "Photo"
  belongs_to :combo
  belongs_to :college

  before_create :lookup_stats
  attr_accessor :score

  scope :for, lambda { |photos| where("photo_id in (#{photos.map(&:id).join(",")})") }
  
  scope :by_photo_ids, lambda{|photo_id, other_photo_id|
    where(:photo_id => photo_id, :other_photo_id => other_photo_id)
  }
  scope :uncomboed, where("combo_id is null")
  scope :unused, uncomboed.where("photo_answer is null") # and friend answer
  scope :good_connections, lambda { |photo_id, threshold|
    where(:photo_id => photo_id). \
    where("(yes_percent > ?  AND vote_count > ?) OR photo_answer_yes > 0 OR (response + other_response > 0)", threshold, 3)
  }

  scope :neither_answered_no, where("photo_answer_no = 0 AND other_photo_answer_no = 0")

  scope :with_approved_other_photo, joins(:other_photo).where("current_state = 'approved'")

  scope :queued_for_response, joins(:combo => :response).where('photo_pairs.response = 0')
  scope :ready_for_response, queued_for_response.where('responses.revealed_at < now()')

  scope :in_progress, includes(:combo).where("combos.active = 't'")

  scope :base_other_photo_match, where("other_photo_answer_yes > 0").
                                 where("photo_answer_yes = 0").
                                 where("photo_answer_no = 0").
                                 where("response = 0")
  
  scope :other_photo_matches, base_other_photo_match.
                              includes(:combo => :response).
                              where("responses.id is null")

  scope :other_photo_matches_to_reveal, base_other_photo_match.
                                        joins(:combo).
                                        where("other_photo_match_revealed_at < now()").
                                        order("other_photo_match_revealed_at desc")

  def initialize(options={})
    photo = options[:photo]
    photo = Photo.find(options[:photo_id]) if photo.nil? && options[:photo_id]
    options[:college_id] = photo.college_id unless photo.nil?
    super
  end


  def self.candidate_pairs_by_profile(reference_photo, limit = 10, photo_ids_to_exclude = [])
    base_scope = Photo.includes(:player => [:user, :preferred_profile, :profile, :facebook_profile]) \
                        .approved \
                        .not_coupled \
                        .excluding_photos(photo_ids_to_exclude) \
                        .within_one_bucket_of(reference_photo)


    if reference_photo.same_sex
      base_scope = base_scope.same_sex(reference_photo)
    else
      base_scope = base_scope.opposite_gender_of(reference_photo)
    end

    if reference_photo.college_id.present?
      return [] unless reference_photo.college.verified?
      base_scope = base_scope.college(reference_photo.college_id)
    else
      base_scope = base_scope.not_college
    end

    candidates = base_scope.order('photos.id desc').limit(500).all.shuffle

    existing_players = {}
    unique_candidates = candidates.select do |candidate|
      if existing_players[candidate.player_id]
        false
      else
        existing_players[candidate.player_id] = true;
      end
    end
    sorted_pairs = unique_candidates.collect do |candidate|
      pair = PhotoPair.new(:photo => reference_photo, :other_photo => candidate)
      pair.lookup_stats
      pair
    end.sort_by(&:score)

    sorted_pairs[0...limit]
  end

  def self.candidate_pairs_by_profile_and_match_me(reference_photo, limit=10)
    candidates = reference_photo.photo_pairs.uncomboed.all
    candidates.map(&:lookup_stats)
    candidates.sort_by(&:calculate_profile_distance)[0...limit]
  end

  def self.candidate_pairs_by_similar_photos(reference_photo, limit=10)
    return [] if reference_photo.same_sex? || (reference_photo.college && !reference_photo.college.verified?)
    similar_photo_candidates_query = <<-sql
      select photo_pairs.other_photo_id as photo_id
      from photos, photo_pairs left join photo_pairs pp on pp.photo_id = #{reference_photo.id} and
                                                   pp.other_photo_id = photo_pairs.other_photo_id and
                                                   pp.combo_id is not null
      where photo_pairs.photo_id in (
          select similar_photo_id from similar_photos
          where photo_id = #{reference_photo.id}
              and similar_count > 3
          order by similar_count desc
          limit 5
        )
        and pp.id is null
        and photo_pairs.yes_percent >= 80
        and photos.id = photo_pairs.other_photo_id
        and photos.current_state = 'approved'
        #{"and photos.college_id = #{reference_photo.college_id}" if reference_photo.college_id.present?}
      order by photo_pairs.yes_percent desc,
               pp.photo_answer_no asc,
               pp.other_photo_answer_no asc,
               pp.photo_answer_yes desc,
               pp.other_photo_answer_yes desc,
               photo_pairs.other_photo_id desc
      limit #{limit * 5}
    sql

    candidate_photo_ids = PhotoPair.connection.select_values(similar_photo_candidates_query).uniq
    candidates = candidate_photo_ids.collect { |id| PhotoPair.new(:photo => reference_photo, :other_photo_id => id) }
    candidates.map(&:lookup_stats)
    candidates.sort_by(&:calculate_profile_distance)[0...limit]
  end

  def self.create_and_update_candidate_pairs_by_correlation(photo, max_to_create = 20)
    Rails.logger.info("create_and_update_candidate_pairs_by_correlation for #{photo.id}")
    all_pairs = candidate_pairs_by_correlation(photo)
    all_pairs[0..max_to_create].map(&:save)
    (all_pairs[max_to_create..-1] || []).each do |pair|
      pair.save unless pair.new_record?
    end
  end

  def self.candidate_pairs_by_correlation(reference_photo, limit = nil)
    other_photo_ids_with_correlation_score(reference_photo.id)[0..(limit || -1)].map {|scored_photo_id|
      attrs = {:photo_id => reference_photo.id, :other_photo_id => scored_photo_id["other_photo_id"]}
      photo_pair = PhotoPair.where(attrs).first || PhotoPair.new(attrs)
      photo_pair.correlation_score = scored_photo_id["correlation_score"]
      photo_pair
    }
  end

  def self.other_photo_ids_with_correlation_score(photo_id)
    connection.select_all <<-SQL
      select correlations.other_photo_id, avg( origin.connection_score * connections.connection_score *  correlations.connection_score) as correlation_score
      from photo_pairs origin
      join photo_pairs connections on (origin.other_photo_id = connections.photo_id)
      join photo_pairs correlations on (connections.other_photo_id = correlations.photo_id)
      where origin.connection_score > 0 AND connections.connection_score > 0
        and origin.photo_id = #{photo_id}
      group by 1
      order by 2 desc
    SQL
  end

  def self.refresh_by_combo_id(combo_id)
    where(:combo_id => combo_id).map(&:refresh_and_save!)
  end

  def self.create_or_refresh_by_combo(combo)
    PhotoPair.transaction do
      create_or_refresh_by_photos_ids(combo.photo_one_id, combo.photo_two_id, combo.id)
      create_or_refresh_by_photos_ids(combo.photo_two_id, combo.photo_one_id, combo.id)
    end
  end

  def self.create_or_refresh_by_photos_ids(photo_id, other_photo_id, combo_id = nil)
    if (photo_pair = PhotoPair.by_photo_ids(photo_id, other_photo_id).first)
      if combo_id
        photo_pair.combo_id = combo_id
      end
      photo_pair.refresh_and_save!
    else
      PhotoPair.create(:photo_id => photo_id, :other_photo_id => other_photo_id, :combo_id => combo_id)
    end
  end

  def refresh_and_save!
    lookup_stats
    save!
    self
  end

  def lookup_stats
    attributes = match_me_stats.
        merge(combo_stats).
        merge(response_stats).
        merge(message_stats).
        merge(distance_stats).
        merge(bucket_stats).
        merge(age_stats)
    self.attributes = attributes
    self.score = calculate_profile_distance
  end

  def age_stats
    if loaded_photo? && loaded_other_photo?
      age_difference = (photo.player.birthdate - other_photo.player.birthdate) / 365 rescue nil
    else
      #TODO facebook
      birthdate_query = <<-SQL
        SELECT birthdate
        FROM photos JOIN players ON photos.player_id = players.id
          LEFT OUTER JOIN profiles ON players.id = profiles.player_id
        WHERE photos.id = %i
      SQL
      photo_birthdate = connection.select_value(birthdate_query % photo_id)
      other_photo_birthdate = connection.select_value(birthdate_query % other_photo_id)

      age_difference = (Date.parse(photo_birthdate) - Date.parse(other_photo_birthdate)) / 365 if photo_birthdate && other_photo_birthdate
    end
    {:age_difference => age_difference}
  end

  def bucket_stats
    bucket_difference = if loaded_photo? && loaded_other_photo?
      photo.bucket_or_default - other_photo.bucket_or_default
    else
      bucket_query = <<-SQL
        SELECT photo.bucket - other_photo.bucket
        FROM photos photo, photos other_photo
        WHERE photo.id = #{photo_id}
          AND other_photo.id = #{other_photo_id}
      SQL
      connection.select_value(bucket_query)
    end

    {:bucket_difference => bucket_difference}
  end

  def distance_stats
    if loaded_photo? && loaded_other_photo?
      distance = photo.player.distance_from(other_photo.player)
    else
      photo_location = location_for(photo_id)
      other_photo_location = location_for(other_photo_id)
      distance = photo_location.distance_from(other_photo_location) rescue 300
    end
    {:distance => distance}
  end

  def location_for(photo_id)
    location_query = <<-SQL
      SELECT geo_lat, geo_lng, location_lat, location_lng
      FROM players LEFT JOIN profiles ON (players.id = profiles.player_id)
      WHERE players.id = (select player_id from photos where id = %i)
    SQL
    results = connection.select_one(location_query % photo_id)
    if results.present?
      lat,lng = if results["location_lat"] && results["location_lng"]
        [results["location_lat"].to_f, results["location_lng"].to_f]
      elsif results["geo_lat"] && results["geo_lng"]
        [results["geo_lat"].to_f, results["geo_lng"].to_f]
      else
        [Player::DEFAULT_LAT, Player::DEFAULT_LNG]
      end
      GeoKit::LatLng.new(lat, lng)
    else
      GeoKit::LatLng.new(0, 0)
    end
  end

  def message_stats
    return {} unless combo_id
    message_sql = <<-SQL
      select photo_id from combo_actions where combo_id = #{combo_id}
    SQL

    messages = connection.select_values(message_sql)
    photo_message_count = messages.select { |message_photo_id| message_photo_id.to_i == photo_id }.length

    {:photo_message_count => photo_message_count, :other_photo_message_count => messages.length - photo_message_count}
  end

  def response_stats
    return {} unless combo_id
    response_sql = <<-SQL
      select photo_one_answer, photo_two_answer, photo_one_id from responses, combos where combos.id = responses.combo_id and combos.id = #{combo_id}
    SQL

    if (response_info = connection.select_one(response_sql)).present?
      position = (photo_id == response_info["photo_one_id"].to_i) ? "one" : "two"
      other_position = position == "one" ? "two" : "one"
      {:response => response_to_i(response_info["photo_#{position}_answer"]),
       :other_response => response_to_i(response_info["photo_#{other_position}_answer"])}
    else
      {}
    end
  end

  def response_to_i(response)
    case response
      when "good", "interested", "uninterested": 1
      when "bad": -1
      else 0
    end
  end

  def combo_stats
    return {} unless combo_id
    combo_sql = <<-sql
      select yes_count, no_count, yes_count + no_count as vote_count, yes_percent from combos
      where id = #{combo_id}
    sql

    connection.select_one(combo_sql)
  end

  def match_me_stats
    #TODO not really the right switch
    return {} if loaded_photo? && loaded_other_photo?
    match_me_sql = <<-sql
      SELECT match_me_answers.*, target_photo.player_id as target_player_id, other_photo.player_id as other_player_id
      FROM match_me_answers, photos target_photo, photos other_photo
      WHERE (
        (target_photo_id = #{photo_id} and other_photo_id = #{other_photo_id} AND target_photo_id = target_photo.id AND other_photo_id = other_photo.id) or
        (target_photo_id = #{other_photo_id} and other_photo_id = #{photo_id} AND target_photo_id = other_photo.id AND other_photo_id = target_photo.id)
      )

    sql
    answers_rows = connection.select_all(match_me_sql)

    answers_rows.inject(Hash.new{ |h,k|h[k] = 0 }) do |hash, row |
      what = row["answer"] == "y" ? "yes" : "no"
      who = case row["player_id"]
        when row["target_player_id"] : "photo"
        when row["other_player_id"] : "other_photo"
        else "friend"
      end
      key = "#{who}_answer_#{what}"
      hash[key] += 1
      hash
    end
  end

  def distance_score
    distance == 0 ? -1 : (Math.log(distance / 20.0) / Math.log(3)).to_i rescue 3
  end

  def age_score
    photo_gender = if loaded_photo?
      photo.gender
    else
      connection.select_value("select gender from photos where id = #{photo_id}")
    end
    delta = age_difference * (((photo_gender == "m" && age_difference <= 0) || (photo_gender == "f" && age_difference > 0)) ? 1 : 2.5) rescue 5.5
    (delta / 2.5).to_i.abs
  end

  def bucket_score
    1.5 * (bucket_difference.nil? ? 4 : bucket_difference.abs)
  end

  def match_me_score
    adjustment = 0
    if photo_answer_no > 0 || other_photo_answer_no > 0
      adjustment = 7
    else
      adjustment -= 4  if photo_answer_yes > 0
      adjustment -= 2  if other_photo_answer_yes > 0
    end
    adjustment
  end

  def calculate_profile_distance
    bucket_score + distance_score + age_score + match_me_score
  end

  def self.recreate
    puts "clearing"
    connection.execute <<-SQL
      delete from photo_pairs;
    SQL


    puts "generating from combos"
    connection.execute <<-SQL
      insert into photo_pairs (combo_id, photo_id, other_photo_id)  (select id, photo_one_id, photo_two_id from combos where id not in(2016, 2023, 2017, 2029));
      insert into photo_pairs (combo_id, photo_id, other_photo_id)  (select id, photo_two_id, photo_one_id from combos where id not in(2016, 2023, 2017, 2029));
    SQL

    puts "generating from match_me_answers"
    connection.execute <<-SQL
      insert into photo_pairs (photo_id, other_photo_id)  (
        select distinct target_photo_id, match_me_answers.other_photo_id
        from match_me_answers left join photo_pairs on (target_photo_id = photo_id and match_me_answers.other_photo_id = photo_pairs.other_photo_id)
        where photo_pairs.id is null
      );
      insert into photo_pairs (photo_id, other_photo_id)  (
        select distinct match_me_answers.other_photo_id, target_photo_id
        from match_me_answers left join photo_pairs on (match_me_answers.other_photo_id = photo_id and target_photo_id = photo_pairs.other_photo_id)
        where photo_pairs.id is null
      );
    SQL

    update_all
  end

  def self.update_all
    update_all_combo_stats
    update_all_response_stats
    update_all_message_stats
    update_all_player_profile_stats
    update_all_match_me
    update_all_connection_scores
  end

  def self.update_all_combo_stats
    Rails.logger.info("update_all_combo_stats")
    connection.execute <<-SQL
      update photo_pairs
      set yes_count = c.yes_count,
          no_count = c.no_count,
          vote_count = c.yes_count + c.no_count,
          yes_percent = c.yes_percent
      from combos c
      where c.id = photo_pairs.combo_id
    SQL
  end

  def self.update_all_response_stats
    Rails.logger.info("update_all_response_stats")
    connection.execute <<-SQL
      update photo_pairs
        set response = case coalesce(r_as_1.photo_one_answer, r_as_2.photo_two_answer, 'blank') when 'bad' then -1 when 'blank' then 0 else 1 end,
      other_response = case coalesce(r_as_1.photo_two_answer, r_as_2.photo_one_answer, 'blank') when 'bad' then -1 when 'blank' then 0 else 1 end
      from photo_pairs pp
      left join combos c_as_1 on (c_as_1.photo_one_id = pp.photo_id and c_as_1.photo_two_id = pp.other_photo_id) left join responses r_as_1 on (c_as_1.id = r_as_1.combo_id)
      left join combos c_as_2 on (c_as_2.photo_two_id = pp.photo_id and c_as_2.photo_one_id = pp.other_photo_id) left join responses r_as_2 on (c_as_2.id = r_as_2.combo_id)
      where pp.id = photo_pairs.id;
    SQL
  end

  def self.update_all_message_stats
    Rails.logger.info("update_all_message_stats")
    connection.execute <<-SQL
      update photo_pairs
        set photo_message_count = coalesce(counts_as_1.photo_one_message_count, counts_as_2.photo_two_message_count, 0),
      other_photo_message_count = coalesce(counts_as_2.photo_one_message_count, counts_as_1.photo_two_message_count, 0)
      from photo_pairs pp
      left join combos c_as_1 on (c_as_1.photo_one_id = pp.photo_id and c_as_1.photo_two_id = pp.other_photo_id) left join message_counts counts_as_1 on (c_as_1.id = counts_as_1.combo_id)
      left join combos c_as_2 on (c_as_2.photo_two_id = pp.photo_id and c_as_2.photo_one_id = pp.other_photo_id) left join message_counts counts_as_2 on (c_as_2.id = counts_as_2.combo_id)
      where pp.id = photo_pairs.id;
    SQL

  end

  def self.update_all_player_profile_stats(photo_id = nil)
    Rails.logger.info("update_all_player_profile_stats")
    connection.execute <<-SQL
      update photo_pairs
      set distance = distance_between(pl1.lat, pl1.lng, pl2.lat, pl2.lng),
          age_difference = (pl1.birthdate - pl2.birthdate) / 365,
          bucket_difference = pl1.bucket - pl2.bucket
      from photo_player_profile pl1, photo_player_profile pl2
      where photo_pairs.photo_id = pl1.id and photo_pairs.other_photo_id = pl2.id
      #{"and (photo_pairs.photo_id = #{photo_id} OR photo_pairs.other_photo_id = #{photo_id})" if photo_id};
    SQL
  end

  def self.update_all_match_me
    Rails.logger.info("update_all_match_me")
    connection.execute <<-SQL
      update photo_pairs
      set photo_answer_yes = coalesce(mmaa_as_target.photo_answer_yes, 0),
          photo_answer_no = coalesce(mmaa_as_target.photo_answer_no, 0),
          other_photo_answer_yes = coalesce(mmaa_as_other.photo_answer_yes, 0),
          other_photo_answer_no = coalesce(mmaa_as_other.photo_answer_no, 0),
          friend_answer_yes = (coalesce(mmaa_as_target.friend_answer_yes, 0) + coalesce(mmaa_as_other.friend_answer_yes, 0)),
          friend_answer_no = (coalesce(mmaa_as_target.friend_answer_no, 0) + coalesce(mmaa_as_other.friend_answer_no, 0))
      from  photo_pairs pp
      left join match_me_answer_aggregates mmaa_as_target on (pp.photo_id = mmaa_as_target.target_photo_id and pp.other_photo_id = mmaa_as_target.other_photo_id)
      left join match_me_answer_aggregates mmaa_as_other on (pp.photo_id = mmaa_as_other.other_photo_id and pp.other_photo_id = mmaa_as_other.target_photo_id)
      where pp.id = photo_pairs.id;
    SQL
  end

  def self.update_all_connection_scores
    Rails.logger.info("update_all_connection_scores")
    max_id = PhotoPair.connection.select_value("select max(id) from photo_pairs").to_i

    (0..(max_id / 1000)).each do |batch|
      connection.execute("update photo_pairs set connection_score = calc_connection_score(photo_pairs.*) where id between #{batch * 1000} and #{batch * 1000 + 999}")
    end
  end

  def self.reveal_other_photo_matches(priority=false)
    player_sending_revealed = {}
    player_receiving_revealed = {}
    already_revealed_pairs = {}
    revealed_count = 0

    other_photo_matches_query = other_photo_matches.
                  where("other_photo_match_revealed_at is null").
                  includes(:photo, :other_photo).
                  order("other_photos_photo_pairs.current_state='approved' desc, photos.bucket asc, other_photos_photo_pairs.bucket desc, distance asc")
    if priority
      other_photo_matches_query = other_photo_matches_query.where("photos.priority_until > now() OR other_photos_photo_pairs.priority_until > now() OR photos.created_at > ? OR other_photos_photo_pairs.created_at > ?", 2.days.ago, 2.days.ago)
    end
    
    other_photo_matches_query.each do |photo_pair|
      if player_sending_revealed[photo_pair.other_photo.player_id].nil? &&
         player_receiving_revealed[photo_pair.photo.player_id].nil? &&
         already_revealed_pairs["#{photo_pair.other_photo.player_id}-#{photo_pair.photo.player_id}"].nil?

        player_sending_revealed[photo_pair.other_photo.player_id] = true
        player_receiving_revealed[photo_pair.photo.player_id] = true
        already_revealed_pairs["#{photo_pair.other_photo.player_id}-#{photo_pair.photo.player_id}"] = true

        photo_pair.build_combo(
          :creation_reason => "otherphotomatch",
          :photo_one_id => photo_pair.photo_id,
          :photo_two_id => photo_pair.other_photo_id
        ) if photo_pair.combo.nil?
        photo_pair.combo.active = false
        if photo_pair.combo.save
          photo_pair.update_attribute(:other_photo_match_revealed_at, Time.new)
          revealed_count += 1
        end
      elsif already_revealed_pairs["#{photo_pair.other_photo.player_id}-#{photo_pair.photo.player_id}"].present?
        photo_pair.update_attribute(:other_photo_match_revealed_at, 3.weeks.from_now)
      end
    end
    revealed_count
  end

end
