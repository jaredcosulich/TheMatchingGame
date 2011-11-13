class Admin::RequestLogsController < AdminController
  def index
    @recent_sessions = LOG_DB.view('date_player/views', :group => true, :limit => 100, :descending => true)["rows"]
  end

  def show
    @player_id = params[:id].to_i
    logs = LOG_DB.view('player/path', :startkey => [@player_id], :endkey => [@player_id, {}], :limit => 100)['rows']
    @player_sessions = Admin::PlayerSession.parse(logs).reverse
  end
end
