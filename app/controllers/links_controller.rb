class LinksController < ApplicationController
  def index
    user = User.find_by_perishable_token(params[:token])

    UserSession.create(user)
    set_current_player(user.player) if user
    if params[:link].to_i == 0
      redirect_to CGI.unescape(params[:link])
    else
      link = Link.find_by_id(params[:link])
      if link.nil?
        redirect_to account_path
      else
        link.clicks.create
        redirect_to(link.path)
      end
    end
  end
end
