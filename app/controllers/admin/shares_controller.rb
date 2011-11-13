class Admin::SharesController < AdminController

  def index    
    @shares = Share.find(:all, :limit => 10, :order => "id desc", :conditions => "status = 'unapproved'")
  end

  def approve
    share = Share.find(params[:id])
    share.approve!
    flash[:notice] = "Share Approved"
    redirect_to admin_shares_path
  end

  def reject
    share = Share.find(params[:id])
    share.reject!
    flash[:notice] = "Share Rejected"
    redirect_to admin_shares_path
  end

end
