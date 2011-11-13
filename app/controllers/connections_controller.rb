class ConnectionsController < ApplicationController
  before_filter :ensure_registered_user
  before_filter :load_combo, :except => :index
  before_filter :set_tab

  def index
    all_connections = @current_player.connections
    @archived_connections, @connections = all_connections.partition do |combo|
      combo.archived_for?(@current_player)
    end
  end

  def show
    unless @combo.connected?
      render :action => "connect"
    else
      @action = ComboAction.new(:photo => @combo.photo_for(@current_player), :combo_id => @combo.id, :action => "message")
      render :action => "message"
    end
  end

  def action
    @combo.combo_actions.create!({:photo => @combo.photo_for(@current_player)}.merge(params[:combo_action])) if params[:combo_action]
  rescue InsufficientCredits
    flash[:notice] = "You do not have enough credits. Please add credits to your account."
  ensure
    redirect_to connection_path(@combo)
  end

  def connect
    if request.get?
      redirect_to connection_path(@combo)      
    else
      @combo.combo_actions.create!({:photo => @combo.photo_for(@current_player)}.merge(:action => "connect", :message =>params[:combo_action][:message]))
      response = Response.find_or_create_by_combo_id(@combo.id)
      player_position = @combo.photo_position_for(@current_player)
      response.update_attribute("#{player_position}_answer", 'interested')
      redirect_to connection_path(@combo)
    end
  rescue InsufficientCredits
    flash[:notice] = "You need to add credits to make this connection"
    render :action => "connect"
  end

  def unlock
    all_params = params.dup
    id = params.delete(:id)
    [:action, :controller].each { |a| params.delete(a) }
    SocialGoldTransaction.verify_signature(params.delete(:sig), params)

    combo = Combo.find(id)
    combo.create_response if combo.response.nil?
    combo.response.update_attribute("#{combo.photo_position_for(@current_player)}_unlocked", true)
    Mailer.delay(:priority => 9).deliver_admin_notification(:subject => "Connection Unlocked", :current_player => @current_player, :combo => combo)
  rescue StandardError => e
    HoptoadNotifier.notify(:parameters => all_params,
                           :error_class => e.class.name,
                           :error_message => "#{e.class.name}: #{e.message}")
    flash[:notice] = "We were unable to unlock this connection. If you think this was in error please contact support@thematchinggame.com"
  ensure
    render :template => "credits/complete", :layout => false
  end

  def archive
    @combo.response.update_attributes("#{@combo.photo_position_for(@current_player)}_archived_at" => params[:archived_at])
    redirect_to connections_path
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
