class Admin::LinksController < AdminController

  def index
    @link_clicks = LinkClick.find(
      :all,
      :joins => :link, 
      :conditions => date_conditions(params, nil, "link_clicks"),
      :order => "links.id desc"
      )
  end

end
