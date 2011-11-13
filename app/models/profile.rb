class Profile < ActiveRecord::Base
  include ProfileBehavior

  belongs_to :player

end
