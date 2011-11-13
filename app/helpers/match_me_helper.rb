module MatchMeHelper
  def name_for(target_photo)
    target_photo.first_name.blank? ? target_photo.him_her : target_photo.first_name
  end
end
