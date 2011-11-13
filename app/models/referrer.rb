class Referrer < ActiveRecord::Base
  has_many :referrals
  has_many :players, :through => :referrals

  validates_presence_of :url

  validates_presence_of :uid
  validates_uniqueness_of :uid

end
