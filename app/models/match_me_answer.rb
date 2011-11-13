class MatchMeAnswer < ActiveRecord::Base
  belongs_to :other_photo, :class_name => "Photo"
  belongs_to :target_photo, :class_name => "Photo"
  belongs_to :player

  validates_presence_of :answer

  def self.uncomboed_good_for_photo(photo_id)
    answers_sql = <<-sql
      SELECT match_me_answers.other_photo_id
      FROM match_me_answers LEFT JOIN combo_scores on (combo_scores.photo_id = match_me_answers.target_photo_id and combo_scores.other_photo_id = match_me_answers.other_photo_id)
      WHERE match_me_answers.answer = 'y'
       AND combo_scores.id is null
       AND match_me_answers.target_photo_id = #{photo_id}
    sql
    connection.select_values(answers_sql)
  end

  def self.nos_with_combos
    sql = <<-sql
      SELECT sum(combos.yes_count) as yes, sum(combos.no_count) as no
      FROM match_me_answers, combo_scores, combos
      WHERE match_me_answers.answer = 'n'
        AND combo_scores.photo_id = match_me_answers.target_photo_id
        AND combo_scores.other_photo_id = match_me_answers.other_photo_id
        AND combo_scores.combo_id = combos.id
        AND match_me_answers.created_at < combos.created_at
    sql
    connection.select_all(sql)
  end

  def self.mutual_good
    query = <<-SQL
      SELECT m1.target_photo_id, m1.other_photo_id
      FROM match_me_answers m1, match_me_answers m2
      WHERE m1.target_photo_id = m2.other_photo_id
        AND m1.other_photo_id = m2.target_photo_id
        AND m1.answer = 'y' and m2.answer = 'y'

    SQL
    MatchMeAnswer.connection.select_all query
  end

  def self.duplicate_answers
    query = <<-SQL
      SELECT player_id, target_photo_id, other_photo_id
      FROM match_me_answers
      WHERE player_id is not null
      GROUP BY 1,2,3
      HAVING count(*) > 1
      ORDER BY 1,2,3
    SQL
    MatchMeAnswer.connection.select_all(query)
  end

  def self.purge_duplicates
    duplicate_answers.each do |duplicate|
      dup_answers = MatchMeAnswer.where(duplicate)
      dup_answers[1..-1].each { |answer| answer.destroy }
    end
  end

  def self.average_answers(days_ago=nil)
    query = "select avg(count) from (select count(*) as count from match_me_answers #{"where created_at > '#{days_ago.days.ago}'" if days_ago.present?} group by player_id) counts"
    MatchMeAnswer.connection.select_value(query).to_i
  end

  def self.friend_suggestions(photo, limit=10, page=0)
    query = <<-sql
      select match_me_answers.other_photo_id, your_answers.answer as answer, count(match_me_answers.answer) as count
      from match_me_answers
      left join match_me_answers as your_answers
        on your_answers.other_photo_id = match_me_answers.other_photo_id and
           your_answers.target_photo_id = #{photo.id} and
           your_answers.player_id = #{photo.player_id}
      where match_me_answers.answer = 'y'
        and match_me_answers.target_photo_id = #{photo.id}
        and match_me_answers.player_id != #{photo.player_id}
      group by 1, 2
      order by 2 desc, 3 desc
      limit #{limit}
      offset #{limit * page}
    sql
    suggestion_data = MatchMeAnswer.connection.select_all(query)

#    query = <<-sql
#      select other_photo_id, (photo_answer_yes + photo_answer_no) as answer, friend_answer_yes as count
#      from photo_pairs
#      where photo_pairs.photo_id = #{photo.id} and
#            photo_pairs.friend_answer_yes > 0
#      order by 2 asc, 3 desc
#      limit #{limit}
#      offset #{limit * page}
#    sql
#    suggestion_data = PhotoPair.connection.select_all(query)
    
    suggestion_data.collect do |data|
      {:photo => Photo.find(data["other_photo_id"]), :count => data["count"], :answer => data["answer"]}
    end
  end
end
