class Transaction < ActiveRecord::Base
  belongs_to :user
  belongs_to :source, :polymorphic => true

  after_create :update_user_credits

  attr_accessor :subscribe

  def update_user_credits
    if subscribe.present?
      if subscribe == "success"
        user.update_attribute(:subscribed_until, 1.month.from_now) if user.subscribed_until.nil?
      end
    else
      user.update_credits(amount)
    end
  end

end
