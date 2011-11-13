class Admin::MatchingPerformance
  def initialize(end_time, duration)
    @end_time = end_time
    @start_time = end_time   - duration
  end

  def report
    photo_ids = photo_ids_in_range
    answer_count = Answer.connection.select_value("SELECT count(id) FROM answers WHERE created_at BETWEEN '#{@start_time}' and '#{@end_time}'")
    combo_count = Combo.connection.select_value("SELECT count(id) FROM combos WHERE created_at BETWEEN '#{@start_time}' and '#{@end_time}'")
    matches_info = matches_in_range(photo_ids)

    data = {:totals => {:photo_count => photo_ids.length, :answer_count => answer_count, :combo_count => combo_count}}

    [:combos, :matches, :responses, :good, :good_good].each do |key|
      total_for_key = matches_info.inject(0) { |total,info| total + (info[1][key] || []).length }
      data[:totals][key] = total_for_key
      data[key] = {
        :total_average => total_for_key.to_f / photo_ids.length.to_f,
        :first_within_3_days => matches_info.inject(0) { |total,info| (info[1][key].present? && info[1][key].min < 3) ? total + 1 : total } * 100 / photo_ids.length,
        :first_within_1_week => matches_info.inject(0) { |total,info| (info[1][key].present? && info[1][key].min < 7) ? total + 1 : total } * 100 / photo_ids.length,
        :average_total_within_1_week => matches_info.inject(0) { |total,info| total + info[1][key].select {|days| days < 7 }.length }.to_f / photo_ids.length.to_f,
        :average_total_within_2_weeks => matches_info.inject(0) { |total,info| total + info[1][key].select {|days| days < 14 }.length }.to_f / photo_ids.length.to_f,
        :average_total_within_1_month => matches_info.inject(0) { |total,info| total + info[1][key].select {|days| days < 31 }.length }.to_f / photo_ids.length.to_f,
      }      
    end
    data
  end

  def photo_ids_in_range
    Photo.connection.select_all("select id from photos where created_at BETWEEN '#{@start_time}' and '#{@end_time}' and photos.current_state in ('approved', 'paused')").map{|row|row["id"]}
  end

  def matches_in_range(photo_ids)
    photo_one_results = combo_query(photo_ids, "one", "two")
    photo_two_results = combo_query(photo_ids, "two", "one")

    photos_with_lag = (photo_one_results + photo_two_results).inject({}) do |hash, row|
      days_to_match = (row["days_to_match"] || row["days_to_response"] || "-1").to_i
      result_row = (hash[row["id"]] ||= {:combos => [], :matches => [], :responses => [], :good => [], :good_good => []})
      result_row[:combos] << row["days_to_combo"].to_i
      result_row[:matches] << days_to_match.to_i if days_to_match >= 0
      result_row[:responses] << days_to_match if row['photo_answer'] != nil
      result_row[:good] << days_to_match if (row['photo_answer'] != 'bad' && row['photo_answer'] != nil)
      result_row[:good_good] << days_to_match if (row['photo_answer'] != 'bad' && row['photo_answer'] != nil && row['other_answer'] != 'bad' && row['other_answer'] != nil)
      hash
    end
    photos_with_lag
  end


  def combo_query(photo_ids, photo_position, other_position)
    Combo.connection.select_all <<-SQL
      SELECT photos.id, photos.created_at, combo_id, photo_#{photo_position}_answer as photo_answer, photo_#{other_position}_answer as other_answer,
        (combos.created_at - photos.created_at) as time_to_combo,
        (photo_#{photo_position}_emailed_at - photos.created_at) as time_to_match,
        (photo_#{photo_position}_answered_at - photos.created_at) as time_to_response,
        date_part('day', combos.created_at - photos.created_at) as days_to_combo,
        date_part('day', photo_#{photo_position}_emailed_at - photos.created_at) as days_to_match,
        date_part('day', photo_#{photo_position}_answered_at - photos.created_at) as days_to_response
      FROM photos, combos left join responses on responses.combo_id = combos.id
      WHERE (photos.id in (#{photo_ids.join(",")}))
        AND photos.id = photo_#{photo_position}_id
        AND photos.current_state in ('approved', 'paused')
      ORDER BY combos.id
    SQL
  end
end
