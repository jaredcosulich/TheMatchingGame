class Admin::RequestLogDetailsController < AdminController

  def show
    @details = LOG_DB.get(params[:id])
  end
end
