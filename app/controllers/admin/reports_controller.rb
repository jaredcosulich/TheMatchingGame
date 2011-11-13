class Admin::ReportsController < AdminController
  def gb_key(answer)
    case answer
      when "good", "interested", "uninterested": "yes"
      when "bad": "no"
      else  ""
    end
  end

  def show
    @daters_visited = User.where(date_conditions(params, nil, "users", "last_request")).count
    @active_combos = Combo.active.count
    @oldest_active_combo = Combo.active.order("created_at asc").first.created_at.strftime("%b %d, %Y")
    @approved_photos = Photo.approved.count
    @active_players_m = Player.joins(:photos).where("photos.current_state = 'approved'").where("photos.gender = 'm'").uniq.count
    @active_players_f = Player.joins(:photos).where("photos.current_state = 'approved'").where("photos.gender = 'f'").uniq.count
    @last_photo_removed_count = Photo.connection.select_value("select count(distinct(photos.player_id)) from photos left join photos p2 on p2.player_id = photos.player_id and p2.id != photos.id and p2.current_state = 'approved' where photos.current_state = 'removed' and p2.id is null#{date_conditions(params, 'and', "photos", "updated")}")
    @deleted_account_count = User.unscoped.where(date_conditions(params, nil, "users", "deleted")).count

    @player_count = Player.count(:conditions => date_conditions(params))
    @male_player_count = Player.count(:conditions => "gender = 'm'#{date_conditions(params, 'and')}")
    @female_player_count = Player.count(:conditions => "gender = 'f'#{date_conditions(params, 'and')}")

    @user_count = User.count(:conditions => date_conditions(params))

    @photo_count = Photo.count(:conditions => date_conditions(params))
    @approved_photo_count = Photo.count(:conditions => "current_state = 'approved'#{date_conditions(params, 'and')}")

    @game_count = Game.count(:conditions => date_conditions(params))

    @referral_count = Referral.count(:conditions => date_conditions(params))

    @fb_count = User.count(:conditions => "fb_id is not null #{date_conditions(params, 'and')}")

    @link_click_count = LinkClick.count(:conditions => date_conditions(params))

    @response_count = Response.count(:conditions => date_conditions(params, nil, nil, :updated))

    @answer_count = Answer.count(:conditions => date_conditions(params))
    @match_me_answer_count = MatchMeAnswer.count(:conditions => "game = 'match_me'#{date_conditions(params, 'and')}")
    @interests_answer_count = MatchMeAnswer.count(:conditions => "game = 'interests'#{date_conditions(params, 'and')}")
    @discover_answer_count = MatchMeAnswer.count(:conditions => "game = 'discover'#{date_conditions(params, 'and')}")
    @club_answer_count = MatchMeAnswer.count(:conditions => "game = 'club'#{date_conditions(params, 'and')}")

    @good_bad_summary = Hash.new{0}
    @responses_summary = Hash.new{0}
    Response.connection.select_all("select photo_one_answer, photo_two_answer, count(*) from responses#{date_conditions(params, 'where', nil, :updated)} group by 1,2 order by 1,2").each do |info|
      @good_bad_summary[[gb_key(info['photo_one_answer']), gb_key(info['photo_two_answer'])].sort.join(" : ")] += info['count'].to_i
      @responses_summary[[info['photo_one_answer'] || "", info['photo_two_answer'] || ""].sort.join(" : ")] += info['count'].to_i
    end

    @combo_actions = ComboAction.connection.select_all("select action, count(*) from combo_actions #{date_conditions(params, 'where')} group by 1 order by 2")

    @challenge_count = Challenge.count(:conditions => date_conditions(params))
    @challenge_player_count = ChallengePlayer.count(:conditions => date_conditions(params))
    @challenge_player_played_count = ChallengePlayer.count(:conditions => "player_id is not null#{date_conditions(params, 'and')}")

    @yes_count = Answer.count(:conditions => "kind='predicted' and answer = 'y'#{date_conditions(params, 'and')}")
    @no_count = Answer.count(:conditions => "kind='predicted' and answer = 'n'#{date_conditions(params, 'and')}")

    @combo_count = Combo.count(:conditions => date_conditions(params))
    @active_combo_count = Combo.active.count(:conditions => date_conditions(params))
    @inactive_combo_count = Combo.inactive.count(:conditions => date_conditions(params))
    @inactivated_combo_count = Combo.inactive.count(:conditions => date_conditions(params, nil, nil, :inactivated))

    @trending_yes_count = Combo.full.active.trending_yes.count(:conditions => date_conditions(params, nil, 'combos'))
    @trending_no_count = Combo.full.active.trending_no.count(:conditions => date_conditions(params, nil, 'combos'))

    @active_yes_count = Combo.active_yes.count(:conditions => date_conditions(params))
    @active_no_count = Combo.active_no.count(:conditions => date_conditions(params))
    @active_many_votes_count = Combo.active_many_votes.count(:conditions => date_conditions(params))

    @inactive_yes_count = Combo.inactive_yes.count(:conditions => date_conditions(params))
    @inactive_no_count = Combo.inactive_no.count(:conditions => date_conditions(params))
    @inactive_many_votes_count = Combo.inactive_many_votes.count(:conditions => date_conditions(params))

    @game_players = Game.connection.execute("select game_count, count(*) from (select player_id, count(player_id) as game_count from games#{date_conditions(params, 'where')} group by player_id) game_counts group by game_count order by game_count")

    @average_answer_player = Game.connection.select_value("select avg(answer_count) from (select count(answers.id) as answer_count from answers where answers.game_id not in (1,2)#{date_conditions(params, 'and', 'answers')} group by player_id) answers_counts")

    @answers_per_player = Answer.connection.select_all("select g.player_id, p.geo_name, ps.accuracy, u.id is not null as registered, ph.id is not null as photos, r.url as referrer_url, r.title as referrer, count(distinct(cp.id)) as challenges, count(distinct(a.id)) as answers from answers a, games g, player_stats ps, players p left outer join challenge_players cp on cp.player_id = p.id left outer join users u on u.player_id = p.id left outer join photos ph on ph.player_id = p.id left outer join referrals on p.id = referrals.player_id left outer join referrers r on referrals.referrer_id = r.id where p.id = g.player_id and p.id = ps.player_id and a.game_id = g.id#{date_conditions(params, 'and', 'a')} group by 1,2,3,4,5,6,7 order by 9 DESC")

    @emailings = [
      Emailing.connection.select_all("select emailings.email_name, email_preferences.prediction_progress as status, count(email_preferences.prediction_progress) as count from emailings, links, link_clicks, users, email_preferences where emailings.id = links.source_id and links.source_type = 'Emailing' and links.id = link_clicks.link_id and emailings.user_id = users.id and users.id = email_preferences.user_id#{date_conditions(params, 'and', 'link_clicks')} and emailings.email_name = 'prediction_progress' group by emailings.email_name, email_preferences.prediction_progress"),
      Emailing.connection.select_all("select emailings.email_name, email_preferences.awaiting_response   as status, count(email_preferences.awaiting_response)   as count from emailings, links, link_clicks, users, email_preferences where emailings.id = links.source_id and links.source_type = 'Emailing' and links.id = link_clicks.link_id and emailings.user_id = users.id and users.id = email_preferences.user_id#{date_conditions(params, 'and', 'link_clicks')} and emailings.email_name = 'response_reminder'   group by emailings.email_name, email_preferences.awaiting_response")
    ].flatten

  end

  def help_responses
    @help_responses = HelpResponse.find(:all, :conditions => date_conditions(params))
  end
end
