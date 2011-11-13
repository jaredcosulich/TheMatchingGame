class Badge < ActiveRecord::Base
  has_many :players, :through => :player

end
