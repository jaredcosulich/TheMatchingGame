class Referral < ActiveRecord::Base
  belongs_to :player
  belongs_to :referrer

  scope :first_time, joins(:player).where('date(players.created_at) >= date(referrals.created_at)')
end
