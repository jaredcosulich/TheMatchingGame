class CrowdflowerJob < ActiveRecord::Base
  belongs_to :user
  before_create :assign_conversion_id
  
  SECRET_KEY = 'c968e130248748a61165b223ff0689e3ff6a7603'

  after_save :assign_credits
  after_create :notify_admin

  def self.signature_valid?(payload, signature)
    Digest::SHA1.hexdigest(payload + SECRET_KEY) == signature
  end

  def assign_conversion_id
    self.conversion_id = UUID.generate(:compact)
  end

  def assign_credits
    if completed_at.present? && completed_at_was.nil?
      user.update_attributes(:credits => user.credits + adjusted_amount)
      AdminMailer.delay(:priority => 9).deliver_notify("Crowdflower Job COMPLETED", "A Crowdflower job was completed!", :priority => self)
    end
  end

  def notify_admin
    AdminMailer.delay(:priority => 9).deliver_notify("Crowdflower Job Created", "A Crowdflower job was created.", :job => self)
  end
end
