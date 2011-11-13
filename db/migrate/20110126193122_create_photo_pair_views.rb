class CreatePhotoPairViews < ActiveRecord::Migration
  def self.up
    execute(match_me_view_sql)
    execute(distance_function_sql)
    execute(photo_player_profile_view_sql)
    execute(message_counts_view_sql)
  end

  def self.down
  end

  def self.photo_player_profile_view_sql
<<SQL
DROP VIEW IF EXISTS photo_player_profile;
CREATE OR REPLACE VIEW photo_player_profile AS
SELECT photos.id, photos.bucket, photos.gender, birthdate, coalesce(location_lat, geo_lat) as lat, coalesce(location_lng, geo_lng) as lng 
FROM photos
  JOIN players on (photos.player_id = players.id)
  LEFT JOIN profiles ON (players.id = profiles.player_id)
SQL
  end

  def self.message_counts_view_sql
<<SQL
DROP VIEW IF EXISTS message_counts;
CREATE OR REPLACE VIEW message_counts AS
SELECT combo_id,
count(case combo_actions.photo_id when combos.photo_one_id then 1 else null end) as photo_one_message_count,
count(case combo_actions.photo_id when combos.photo_two_id then 1 else null end) as photo_two_message_count
FROM combo_actions, combos
WHERE combo_actions.combo_id = combos.id
GROUP BY 1
SQL
  end

  def self.distance_function_sql
<<SQL
DROP FUNCTION IF EXISTS distance_between(lat1 numeric, lng1 numeric, lat2 numeric, lng2 numeric, OUT distance integer);
CREATE FUNCTION distance_between(lat1 numeric, lng1 numeric, lat2 numeric, lng2 numeric, OUT distance integer) AS $$
 SELECT cast(3963.0 * acos(greatest(-1, least(1, (sin($1/57.2958) * sin($3/57.2958) + cos($1/57.2958) * cos($3/57.2958) *  cos($4/57.2958 -$2/57.2958))))) as integer);
$$ LANGUAGE SQL;
SQL
  end

  def self.match_me_view_sql
<<SQL
DROP VIEW IF EXISTS match_me_answer_aggregates;
CREATE OR REPLACE VIEW match_me_answer_aggregates AS
SELECT target_photo_id, other_photo_id,
  count(
    case match_me_answers.player_id
      when target_photo.player_id then (case answer when 'y' then 1 else null end)
      else null
    end
  ) as photo_answer_yes,
  count(
    case match_me_answers.player_id
      when target_photo.player_id then (case answer when 'n' then 1 else null end)
      else null
  end
  ) as photo_answer_no,
  count(
    case match_me_answers.player_id
      when other_photo.player_id then (case answer when 'y' then 1 else null end)
      else null
    end
  ) as other_photo_answer_yes,
  count(
    case match_me_answers.player_id
      when other_photo.player_id then (case answer when 'n' then 1 else null end)
      else null
  end
  ) as other_photo_answer_no,
  count(
    case match_me_answers.player_id
      when target_photo.player_id then null
      when other_photo.player_id then null
      else (case answer when 'y' then 1 else null end)
    end
  ) as friend_answer_yes,
  count(
    case match_me_answers.player_id
      when target_photo.player_id then null
      when other_photo.player_id then null
      else (case answer when 'n' then 1 else null end)
    end
  ) as friend_answer_no
FROM match_me_answers, photos target_photo, photos other_photo
WHERE target_photo_id = target_photo.id AND other_photo_id = other_photo.id
GROUP BY target_photo_id, other_photo_id
SQL
  end
end
