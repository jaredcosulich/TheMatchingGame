class ComboResponsesController < ApplicationController
  before_filter :ensure_registered_user

  def show
    redirect_to root_path
  end

  def create
    response = Response.scoped.includes(:combo).find_or_create_by_combo_id(params[:combo_id])

    player_position = response.combo.photo_position_for(@current_player)

    raise NotAuthorized unless player_position
    begin
      response_param = params[:response].split(/\s/)
      updates = {"#{player_position}_answer" => response_param.first}
      updates.merge!("#{player_position}_rating" => response_param[1].gsub("rating_", "")) if response_param.length > 1
      response.update_attributes(updates)      
      render :json => response.combo.to_json
    rescue => e
      render :json => {:error => e.class.name}, :status => 500
    end
  end

end
