class Admin::TransactionsController < AdminController

  def index
    @social_gold_transactions = SocialGoldTransaction.order('id desc').includes(:user => {:player => [:profile, :facebook_profile]}).all
  end

end

