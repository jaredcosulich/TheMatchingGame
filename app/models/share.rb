class Share < ActiveRecord::Base
  belongs_to :player

  after_create :notify_admins

  include AASM
  aasm_column :status
  attr_protected :status
  aasm_initial_state :unapproved

  aasm_state :unapproved
  aasm_state :approved, :after_enter => :send_email
  aasm_state :rejected
  aasm_state :sent

  aasm_event :approve do
    transitions :to => :approved, :from => [:unapproved]
  end
  aasm_event :reject do
    transitions :to => :rejected, :from => [:unapproved]
  end
  aasm_event :sent do
    transitions :to => :sent, :from => [:approved]
  end


  def notify_admins
    Mailer.delay(:priority => 2).deliver_share_notification(self.id)
  end

  def send_email
    Mailer.delay(:priority => 2).deliver_share_message(self.id)
  end
end
