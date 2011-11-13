require "stripe"
class WantPayment < ActiveRecord::Base
  belongs_to :user

  before_save :set_amount
  before_save :make_payment
  after_save  :update_user_last_payment
  after_save  :admin_notification

  attr_accessor :amount_dollars, :amount_cents, :card_info, :email

  def set_amount
    self.amount_dollars = 0 if amount_dollars.nil?
    self.amount_cents = 0 if amount_cents.nil?
    unless amount_dollars == 0 && amount_cents == 0
      self.amount = (amount_dollars.to_i * 100) + amount_cents.to_i
    end
    self.amount_dollars = nil if amount_dollars == 0
    self.amount_cents = nil if amount_cents == 0
  end

  def make_payment
    return if amount.nil? || charge_id.present?
    Stripe.api_key = STRIPE_API_KEY
    customer_id = get_customer_id
    return false if !customer_id
    self.customer_id = customer_id
    if amount < 50
      self.charge_id = "VERYLITTLE - #{amount}"
    else
      charge = Stripe::Charge.create(
        :amount => amount, :currency => "usd",
        :customer => customer_id,
        :description => "#{user.id} - #{email}"
      )
      self.charge_id = charge.id
    end
  end

  def get_customer_id
    begin
      customer_id = user.want_payments.where("customer_id is not null").order("id desc").first
      return customer_id unless customer_id.nil?
      customer = Stripe::Customer.create(
        :description => "#{user.id} - #{email}",
        :email => email,
        :card => card_info
      )
      customer.id
    rescue Exception => e
      AdminMailer.delay(:priority => 9).deliver_notify("Payment Error", "There was an error creating a customer", :error => e, :payment => self.inspect)
      return false
    end
  end

  def update_user_last_payment
    return if charge_id.nil?
    user.update_attributes(:last_payment => updated_at)
  end

  def admin_notification
    return if charge_id.nil?
    AdminMailer.delay(:priority => 9).deliver_notify("New Payment", "A payment was saved", :payment => self)
  end

  def self.existing_customer?(user)
    user.want_payments.where("customer_id is not null").count > 0
  end
end
