class TapjoyOffer < ActiveRecord::Base
  belongs_to :user

  SECRET_KEY = '1145840006017930'

  after_create :assign_credits
  after_create :notify_admin

  def self.signature_valid?(params, signature)
    Digest::MD5.hexdigest("#{params[:id]}:#{params[:snuid]}:#{params[:currency]}:#{SECRET_KEY}") == signature
  end

  def assign_credits
    user.update_attributes(:credits => user.credits + credits)
  end

  def notify_admin
    AdminMailer.delay(:priority => 9).deliver_notify("Tapjoy Offer COMPLETED", "A Tapjoy offer was completed.", :offer => self)
  end
end
