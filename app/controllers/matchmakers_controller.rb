class MatchmakersController < ApplicationController
  before_filter :set_tab

  def index
    
  end


  private

  def set_tab
    @selected_tab = "matchmakers"
  end
end
