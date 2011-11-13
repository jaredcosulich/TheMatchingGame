class College::RankingsController < ApplicationController
  layout "college"

  before_filter :set_tab

  LEADERS_PER_PAGE = 6

  def index
    @current_player_stat = @current_player.current_stat
    leaders = Player.leaderboard(@current_player).
                     includes(:photos).
                     order("player_stats.correct_count desc").
                     order("players.id = #{@current_player.id} desc").
                     order("players.id desc").
                     limit(LEADERS_PER_PAGE)

    ranking = Player.leaderboard(@current_player).
                     includes(:photos).
                     where("correct_count > ?", @current_player.correct_count)


    if @current_player.college.present? && @current_player.college.verified?
      leaders = leaders.where("photos.college_id = ?", @current_player.college_id)
      ranking = ranking.where("photos.college_id = ?", @current_player.college_id)
    else
      leaders = leaders.where("photos.id is not null")
      ranking = ranking.where("photos.id is not null")
    end
    @ranking = ranking.count + 1

    if params.include?(:top) || params.include?(:page)
      @page = (params[:page] || 0).to_i
    else
      @page = @ranking / LEADERS_PER_PAGE
    end
    @leaders = leaders.offset(LEADERS_PER_PAGE * @page)
  end

  protected
  def set_tab
    @selected_tab = "rankings"
  end
end
