class Admin::Snapshot
  def initialize(end_time, duration)
    @end_time = end_time + 8.hours
    @start_time = end_time - duration + 8.hours
  end

  def report
    {
      :players => players,
      :daters => daters(players[:new]),
      :answers => answers(players[:total]),
      :combos => combos,
      :responses => responses,
      :transactions => transactions,
      :messages => messages
    }
  end

  def players
    players_with_answer_count = select_all <<-SQL
      SELECT players.id, count(answers.id)
      FROM players left outer join games on (players.id = games.player_id)
        left outer join answers on (games.id = answers.game_id)
      WHERE games.created_at BETWEEN '#{@start_time}' and '#{@end_time}'
         OR players.created_at BETWEEN '#{@start_time}' and '#{@end_time}'
      GROUP BY 1
      SQL

    new_players = select_all <<-SQL
      SELECT players.id, count(referrals.id)
      FROM players LEFT OUTER JOIN referrals on referrals.player_id = players.id
      WHERE players.created_at BETWEEN '#{@start_time}' and '#{@end_time}'
      GROUP BY 1
    SQL

    five_answer_percent = players_with_answer_count.select { |p| p["count"].to_i >= 5 }.length * 100 / players_with_answer_count.length rescue "n/a"
    ten_answer_percent = players_with_answer_count.select { |p| p["count"].to_i >= 10 }.length * 100 / players_with_answer_count.length rescue "n/a"
    fifteen_answer_percent = players_with_answer_count.select { |p| p["count"].to_i >= 15 }.length * 100 / players_with_answer_count.length rescue "n/a"
    no_referral_percent = new_players.select { |p| p["count"].to_i == 0 }.length * 100 / new_players.length rescue "n/a"
    {
      :total => players_with_answer_count.length,
      :five_answer_percent => five_answer_percent,
      :ten_answer_percent => ten_answer_percent,
      :fifteen_answer_percent => fifteen_answer_percent,
      :new => new_players.length,
      :no_referral_percent => no_referral_percent
    }
  end

  def daters(new_players)
    daters_with_join_date = select_all <<-SQL
      SELECT player_id, gender, min(photos.created_at)
      FROM  photos
      WHERE couple_combo_id is null AND current_state != 'rejected'
      GROUP BY 1,2
      HAVING min(photos.created_at) BETWEEN '#{@start_time}' and '#{@end_time}'
    SQL

    percent_of_players = daters_with_join_date.length * 1000 / new_players / 10.0 rescue "n/a"
    female_percent = daters_with_join_date.select{|row|row['gender'] == 'f'}.length * 100 / daters_with_join_date.length rescue "n/a"
    {
      :percent_of_players => percent_of_players,
      :new => daters_with_join_date.length,
      :female_percent => female_percent
    }
  end

  def answers(player_count)
    base_query = <<-SQL
      SELECT count(*) as total, sum(case answer when 'y' then 1 else 0 end) * 100 / count(*) as yes_percent
      FROM answers
      WHERE kind='predicted' and created_at BETWEEN '#{@start_time}' and '#{@end_time}'
    SQL
    info = select_all(base_query).first
    {
      :total => info['total'].to_i,
      :average => info['total'].to_i / player_count,
      :yes_percent => info['yes_percent'].to_i
    }
  end

  def combos
    base_query = <<-SQL
      SELECT count(*)
      FROM combos
      WHERE yes_count + no_count >= 3 AND
        inactivated_at BETWEEN '#{@start_time}' and '#{@end_time}'
    SQL
    total = select_value(base_query).to_i
    good_percent = select_value(base_query + " AND yes_percent >= 55").to_i * 100 / total rescue "n/a"
    {
      :total => total,
      :good_percent => good_percent
    }
  end

  def responses
    base_query = <<-SQL
      SELECT photo_XXX_answer as answer, count(photo_XXX_answer)
      FROM responses
      WHERE photo_XXX_answered_at BETWEEN '#{@start_time}' and '#{@end_time}'
      GROUP by 1
    SQL
    totals_one = select_all(base_query.gsub(/XXX/, "one"))
    totals_two = select_all(base_query.gsub(/XXX/, "two"))

    good_good = select_value <<-SQL
      SELECT count(*)
      FROM responses
      WHERE updated_at BETWEEN '#{@start_time}' and '#{@end_time}'
        AND photo_one_answer is not null
        AND photo_two_answer is not null
        AND photo_one_answer != 'bad'
        AND photo_two_answer != 'bad'
    SQL

    response_total = totals_one.inject(0) { |total,e| total + e["count"].to_i } + totals_two.inject(0) { |total,e| total + e["count"].to_i }
    good_percent = (
      totals_one.inject(0) { |total, row| row['answer'] != 'bad' ? total + row['count'].to_i : total } +
      totals_two.inject(0) { |total, row| row["answer"] != 'bad' ? total + row['count'].to_i : total }
    ) * 100 / response_total rescue "n/a"

    good_good_percent = (good_good.to_i * 100 / response_total) rescue "n/a"

    {
      :total => response_total,
      :good_percent => good_percent,
      :good_good => good_good_percent
    }
  end

  def messages
    base_scope    = ComboAction.where("created_at between ? and ?", @start_time, @end_time)
    message_count = base_scope.count
    connect_count = base_scope.where(:action => "connect").count
    replied_count = base_scope.where(:action => "message").map(&:combo_id).uniq.length
    player_count = base_scope.includes(:photo).map(&:photo).map(&:player_id).uniq.length

    {
      :messages => message_count,
      :replied => replied_count,
      :connections => connect_count,
      :players => player_count
    }
  end

  def transactions
    social_gold_transactions = SocialGoldTransaction.where("created_at between ? and ?", @start_time, @end_time)
    events = social_gold_transactions.map { |t| t.event_type || t.extra_fields["event"] }

    {:subscription_activated => events.select { |e| e == "subscription_activated" }.length,
     :subscription_cancelled => events.select { |e| e == "subscription_cancelled" }.length,
     :payment_success        => events.select { |e| e == "payment_success" }.length,
     :bought_currency        => events.select { |e| e == "BOUGHT_CURRENCY" }.length
    }
  end

  delegate :select_value, :select_all, :to => :connection

  def connection
    Player.connection
  end

end
