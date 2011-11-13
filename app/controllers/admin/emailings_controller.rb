class Admin::EmailingsController < AdminController
  def show
    @emailing = Emailing.find(params[:id])
  end
end
