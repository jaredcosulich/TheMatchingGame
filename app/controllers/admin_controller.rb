class AdminController < ApplicationController
  before_filter :ensure_registered_user
  before_filter :require_admin
  
  rescue_from StandardError, :with => :rescue_action_locally


  def viewport_content
    "initial-scale=1.0"
  end

  protected

  def rescue_action_locally(exception)
    render :text => ([exception.class.to_s, exception.message, exception.inspect] + exception.backtrace).join("<br/>")
  end

  def require_admin
    not_found unless @current_player.admin?
  end

  def date_conditions(params, type=nil, table=nil, action=:created)
    if params[:d].blank? ||  params[:d] == 'today'
      start_date = 8.hours.ago.beginning_of_day
    elsif params[:d] == 'yesterday'
      start_date = (24 + 8).hours.ago.beginning_of_day
      end_date = (24 + 8).hours.ago.end_of_day
    elsif params[:d] == 'same_day_last_week'
      start_date = ((24 * 7) + 8).hours.ago.beginning_of_day
      end_date = ((24 * 7) + 8).hours.ago.end_of_day
    elsif params[:d] == 'last_week'
      start_date = ((24 * 7) + 8).hours.ago.beginning_of_week
      end_date = ((24 * 7) + 8).hours.ago.end_of_week
    elsif params[:d] == 'running_week'
      start_date = 7.days.ago
      end_date = Time.now
    elsif params[:d] == 'this_week'
      start_date = 8.hours.ago.beginning_of_week
    elsif params[:d] =~ /\d+/
      start_date = ((24 * params[:d].to_i) + 8).hours.ago.beginning_of_day
      end_date = ((24 * params[:d].to_i) + 8).hours.ago.end_of_day
    end

    date_conditions = []
    date_conditions << ["#{"#{table}." if table}#{action}_at > '#{start_date + 8.hours}'"] if start_date
    date_conditions << ["#{"#{table}." if table}#{action}_at < '#{end_date + 8.hours}'"] if end_date
    date_conditions = date_conditions.empty? ? nil : "(#{date_conditions.join(" AND ")})"
    return date_conditions.nil? ? nil : " AND #{date_conditions}" if type == 'and'
    return date_conditions.nil? ? nil : " WHERE #{date_conditions}" if type == 'where'
    date_conditions
  end
end
