require 'net/http'
require 'uri'

class CreditsController < ApplicationController
  before_filter :ensure_registered_user, :except => [:create, :earn]
  before_filter :set_tab

  def show
    @credit_history_url = SocialGoldTransaction.buy_credits_url(@current_player.user)
  end

  def watch
    cookies.delete 'last_checked_show_videos'
    cookies.delete 'show_videos_response'
    @selected_subtab = "watch"
  end

  def earn
  end

  def work
  end

  def new
  end

  def complete
    sig = params.delete(:sig)
    subscribe = params.delete(:subscribe)
    [:action, :controller].each { |a| params.delete(a) }
    SocialGoldTransaction.verify_signature(sig, params)
    if params[:status] == "failure"
      flash[:notice] = "There was a problem with this transaction. Please let me know if the problem persists."
    else
      begin
        if subscribe.present?
          @transaction = @current_player.user.transactions.create!(:external_ref_id => params[:external_ref_id], :subscribe => subscribe)
        else
          premium_currency_amount = SocialGoldTransaction.get_premium_currency_amount(@current_player.user.id, params[:external_ref_id])
          @transaction = @current_player.user.transactions.create!(:amount => premium_currency_amount / 100, :external_ref_id => params[:external_ref_id])
          flash[:notice] = "#{@transaction.amount} credits were successfully added to your account."
        end
      Mailer.delay(:priority => 9).deliver_admin_notification(:subject => "Credit Complete", :player => @current_player, :transaction => @transaction)
      rescue ActiveRecord::StatementInvalid => e
        raise e unless e.inspect =~ /duplicate key/
      end
    end
  rescue SocialGoldTransaction::InvalidSignature
    flash[:notice] = "There was a problem verifying this transaction."
  ensure
    render :action => "complete", :layout => false
  end

  def create
    social_gold_params = params.dup
    [:action, :controller].each { |a| social_gold_params.delete(a) }
    transaction = SocialGoldTransaction.create(social_gold_params)
    Mailer.delay(:priority => 9).deliver_admin_notification(:subject => "Credit Created", :transaction => transaction)
  rescue SocialGoldTransaction::InvalidSignature => e
    HoptoadNotifier.notify(:parameters => params,
                           :error_class => e.class.name,
                           :error_message => "#{e.class.name}: #{e.message}")
  ensure
    head 200
  end

  def log_all_requests?
    true
  end

  private

  def set_tab
    @selected_tab = "priorities"
  end

end

