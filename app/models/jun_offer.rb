class JunOffer < ActiveRecord::Base
  belongs_to :user

  after_create :assign_credits

  def assign_credits
    user.update_attributes(:credits => user.credits + 1)
  end
end
