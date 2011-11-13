class Admin::PlayersController < AdminController
  def index
    @recent_players = Answer.connection.select_all <<-SQL
    select g.player_id, p.geo_name, ps.answer_weight, ps.accuracy, max(g.created_at) as created_at, count(*), count(photos.*) as photo_count
    from answers, games g, player_stats ps, players p left join photos on photos.player_id = p.id
    where p.id = g.player_id and p.id = ps.player_id
      and answers.game_id = g.id#{date_conditions(params, 'and', 'answers')}
      group by 1,2,3,4
      order by max(g.created_at) desc
      limit 50
    SQL
  end

  def create
    if params[:player].include?(:photo_id)
      photo = Photo.find_by_id(params[:player][:photo_id])
      redirect_to admin_players_path and return if photo.nil?
      redirect_to admin_player_path(photo.player)
      return
    end
    redirect_to admin_players_path
  end

  def show
    @player = Player.find(params[:id], :include => [:photos, :profile])
    @removed_photos = Photo.removed.where(:player_id => @player.id)
  end

  def emails
    @player = Player.find(params[:id], :include => [:user => {:emailings => {:links => :clicks}}])
  end

  def map
    @players = Player.joins(:photos, :user).where("current_state = 'approved'").where("last_request_at > ?", 3.months.ago).uniq
  end

  def all_photos_removed
    removed_player_ids = Photo.removed.all.map(&:player_id).uniq
    other_photos_player_ids = Photo.approved.where("player_id in (#{removed_player_ids.join(',')})").all.map(&:player_id).uniq
    actually_removed_player_ids = removed_player_ids - other_photos_player_ids
    @removed_player_photos = Photo.removed.where("player_id in (#{actually_removed_player_ids.join(',')})").order("updated_at desc").limit(20)
  end

  def deleted_accounts
    deleted_users = User.unscoped.where("deleted_at is not null").order("deleted_at desc")
    @deleted_user_player_photos = Photo.removed.where("player_id in (#{deleted_users.map(&:player_id).join(',')})").order("updated_at desc").limit(20)
  end

  def impersonate
    player = Player.find(params[:id])
    session['admin_impersonating'] = @current_player.id
    @current_player = player
    UserSession.create(player.user) if player.user
    redirect_to account_path
  end
end
