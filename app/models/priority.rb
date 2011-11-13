class Priority < ActiveRecord::Base
  belongs_to :photo
  belongs_to :user

  CREDITS_MULTIPLIER = 2
  DAYS_PER_CREDIT = 1

  before_create:ensure_user_has_enough_credits
  before_create :set_and_apply_days_purchased
  after_create :notify_admins

  private

  def ensure_user_has_enough_credits
    self.user = photo.player.user
    credits = (credits_applied || 0)
    return false if credits <= 0 || user.credits < credits
  end

  def set_and_apply_days_purchased
    self.days_purchased = (credits_applied / CREDITS_MULTIPLIER) * DAYS_PER_CREDIT
    existing_priority = photo.priority_until
    existing_priority = 1.minute.from_now if existing_priority.nil? || existing_priority < Time.new
    photo.update_attributes(:priority_until => existing_priority + days_purchased.days)
    user.update_attributes(:credits => user.credits - credits_applied)
  end

  def notify_admins
    AdminMailer.delay(:priority => 9).deliver_notify("Priority Created", "A priority was created for photo #{photo_id} with #{credits_applied} credits applied.", :priority => self)
  end

end
