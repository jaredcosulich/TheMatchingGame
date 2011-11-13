class PlayerBadge < ActiveRecord::Base
  belongs_to :player
  belongs_to :badge
end
