class AddScoreFunction < ActiveRecord::Migration
  def self.up
    execute(score_function_sql)
  end

  def self.down
  end

  def self.score_function_sql
<<SQL
DROP FUNCTION IF EXISTS calc_connection_score(photo_pairs);
CREATE FUNCTION calc_connection_score(photo_pairs) RETURNS float8 AS $$
  SELECT CAST(LEAST(100,
    CASE
      WHEN ($1.photo_message_count > 0 AND $1.other_photo_message_count > 0) THEN 150
      WHEN $1.response > 0 AND $1.other_response > 0 THEN 70
      WHEN $1.photo_answer_yes > 0 AND $1.other_photo_answer_yes > 0 THEN 60
      ELSE 0
    END
    +
    CASE
      WHEN $1.combo_id is NULL THEN 0
      ELSE
        ($1.yes_percent - 50)
    END
    +
    CASE
      WHEN ($1.response > 0) THEN 15
      WHEN ($1.response < 0) THEN -30
      ELSE 0
    END
    +
    CASE
      WHEN ($1.other_response > 0) THEN 15
      WHEN ($1.other_response < 0) THEN -30
      ELSE 0
    END
    +
    ($1.photo_answer_yes * 15)
    +
    ($1.photo_answer_no * -15)
    +
    ($1.other_photo_answer_yes * 15)
    +
    ($1.other_photo_answer_no * -15)
    +
    ($1.friend_answer_yes * 5)
    +
    ($1.friend_answer_no * -5)
  ) as float8) / 100;
$$ LANGUAGE SQL;
SQL
  end

end

__END__
yes_percent
photo_answer_yes + photo_answer_no -
other_photo_answer_yes + other_photo_answer_no
friend_answer + friend_answer_no
response
other_response
photo_message_count
other_photo_message_count



100
  - photo_message_count > 0 && other_photo_message_count > 0




mutual message
mutual response good
mutual match me

friend yes
crowd yes


photo_answer_yes, photo_answer_no, other_photo_answer_yes, other_photo_answer_no, friend_answer_yes, friend_answer_no, yes_percent, response, other_response, photo_message_count, other_photo_message_count
