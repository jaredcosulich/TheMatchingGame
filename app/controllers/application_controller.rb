class ApplicationController < ActionController::Base
  include ApplicationHelper
  include SubdomainLocales

  before_filter :handle_player
  after_filter :set_player_on_session
  before_filter :handle_referral
  before_filter :set_referral_cookie
  before_filter :set_stumbleupon_referral_cookie
  after_filter :incremenent_page_view_count
  after_filter :log_stuff
#  before_filter :require_payment

#  rescue_from Exception, :with => :rescue_action_in_public_without_hoptoad
#  rescue_from InsufficientCredits, :with => :insufficient_credits
#  rescue_from NotAuthorized, :with => :not_authorized
#  rescue_from ActionController::RoutingError, :with => :not_found
#  rescue_from ActiveRecord::RecordNotFound, :with => :not_found

  #TODO enable and test
#  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  def show_user_voice
    true
  end

  def not_found
    render "shared/not_found", :status => 404
  end

  def viewport_content
    "width=740"
  end

  private
  def handle_player
    unless session['player_id'] && (session_player = Player.includes(:user).find_by_id(session['player_id']))
      set_current_player(Player.new)
      return
    end

    unless (session_user = session_player.user).present?
      set_current_player(session_player)
      return
    end

    if (user_session = UserSession.find) && (session_player.id == user_session.user.player_id)
      set_current_player(session_player)
    else
      set_current_player(Player.new)
    end
  end

  def log_stuff
    return unless LOG_DB && log_all_requests?
    Timeout.timeout 1 do
      LOG_DB.save_doc({:time => Time.now, :player => @current_player, :request => request_hash, :response => response_hash, :session => session, :cookies => cookies})
    end
  rescue Timeout::Error
  rescue RestClient::UnsupportedMediaType
  rescue => e
    HoptoadNotifier.notify(e, :request => request, :session => session)
  end

  def log_all_requests?
    false
  end

  def request_hash
    [:path, :ip, :params, :referer, :remote_ip, :format, :request_method, :user_agent].inject({}){|hash, name| hash[name] = request.send(name); hash}
  end

  def response_hash
    [:status].inject({}){|hash, name| hash[name] = response.send(name); hash}
  end

  def set_referral_cookie
    cookies['r'] = params[:r] if params.include?(:r)
  end

  def set_stumbleupon_referral_cookie
    cookies['r'] = "stumble#{"_#{params[:action]}" if params[:controller] == "profile_game"}" if  /stumbleupon/.match(request.env["HTTP_REFERER"])
  end

  def handle_referral
    return unless cookies['r']
    referrer = Referrer.find_by_uid(cookies['r'])
    return unless referrer
    Referral.create(:referrer => referrer, :player => @current_player, :locale => locale_subdomain)
    cookies.delete 'r'
  end

  def set_current_player(player)
    @current_player = player.nil? ? Player.new : player
    NewRelic::Agent.add_custom_parameters(:player_id => @current_player.id)
  end

  def set_player_on_session
    session["player_id"] = @current_player.nil? ? nil : @current_player.id
  end

  def requires_message(requirement_message, action_name)
    return nil
  end

  def ensure_registered_user
    unless (@current_player.user)
      flash[:notice] = requires_message("Please sign in or register", action_name)
      store_post_login_destination
      redirect_to new_session_path
      return false
    end
  end

  def store_post_login_destination
    cookies['post_login_path'] = url_for(params.merge(:only_path => true))
  end

  def incremenent_page_view_count
    return if @current_player.nil? || @current_player.new_record?
    if response.content_type == "text/html" && response.code == "200" && !response.redirect? && response.body.strip.length > 0
      Player.connection.execute("update players set pages_visited = pages_visited + 1 where id = #{@current_player.id}")
    end
  end

  def clear_cookies
    cookies.delete('post_login_path')
    session.clear
  end

  def redirect_to_after_login(default=nil)
    path = cookies['post_login_path'] || default
    cookies.delete 'post_login_path'
    redirect_to path unless path.nil?
  end

  def not_authorized
    render "shared/not_authorized", :status => 403
  end

  def insufficient_credits
    render :nothing => true, :status => 402
  end

  def rescue_action_in_public_without_hoptoad(exception)
    if exception.is_a?(ActiveRecord::RecordNotFound) || exception.is_a?(ActionController::RoutingError)
      render "shared/not_found", :status => 404
    else
      render "shared/error", :status => 500
    end
  end

  def require_payment
    return true if self.is_a?(WantPaymentsController) || @current_player.admin?
    if @current_player.present? && @current_player.user.present? && @current_player.college_id.nil? && @current_player.user.needs_to_pay?
      redirect_to want_payments_path
      return false
    end
    return true
  end

end
