class WantPaymentsController < ApplicationController
  before_filter :ensure_registered_user
  before_filter :set_payment_screen

  def index
    @existing_customer = true if WantPayment.existing_customer?(@current_player.user)
    @want_payment = @current_player.user.want_payments.last
    if @want_payment.nil? || @want_payment.charge_id.present?
      @want_payment = @current_player.user.want_payments.create!
    end
  end

  def update
    @want_payment = @current_player.user.want_payments.last
    payment_params = params[:want_payment].merge(
      :email => params[:email],
      :card_info => params[:stripeToken]
    )
    if @want_payment.update_attributes(payment_params)
      flash[:notice] = "Thanks for the support!"
      redirect_to_after_login(account_path)
      return
    else
      if @want_payment.amount == 0
        flash[:notice] = "There was an error. Please make sure you've specified an amount to pay."
      else
        flash[:notice] = "There was an error. Please check that you've filled in all of the fields below."
      end
      render :action => :index
    end
  end

  def set_payment_screen
    @payment_screen = true
  end

end
