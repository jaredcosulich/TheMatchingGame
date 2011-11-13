class College::ConnectionsController < ApplicationController
  layout "college"

  before_filter :load_combo, :except => :index
  before_filter :set_tab

  def index
    all_connections = @current_player.connections
    @archived_connections, @connections = all_connections.partition do |combo|
      combo.archived_for?(@current_player)
    end
    @connections = @connections[0..4]
  end

  def action
    combo_action = @combo.combo_actions.create!({:photo => @combo.photo_for(@current_player)}.merge(params[:combo_action])) if params[:combo_action]
    render :partial => "message", :locals => {:combo_action => combo_action}
  end

  def connect
    if request.get?
      redirect_to college_connections_path
    else
      combo_action = @combo.combo_actions.create!({:photo => @combo.photo_for(@current_player)}.merge(:action => "connect", :message =>params[:combo_action][:message]))
      response = Response.find_or_create_by_combo_id(@combo.id)
      player_position = @combo.photo_position_for(@current_player)
      response.update_attribute("#{player_position}_answer", 'interested')
      render :partial => "message", :locals => {:combo_action => combo_action}
    end
  end

  protected
  def load_combo
    @combo = Combo.find(params[:id], :include => [{:photo_one => :player}, {:photo_two => :player}])
    raise NotAuthorized unless [@combo.photo_one.player, @combo.photo_two.player].include?(@current_player)
    @other_actor = @combo.other_actor(@current_player)
    @combo_actions = @combo.combo_actions.connects_and_messages
    @combo_actions.reject { |ca| ca.actor?(@current_player) }.each { |ca| ca.update_attribute(:viewed_at, Time.new.utc)}
  end

  def set_tab
    @selected_tab = "connections"
  end
end
