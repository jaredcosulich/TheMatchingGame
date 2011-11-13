class MatchMeCombo
  attr_reader :photo, :other_photo, :photo_one, :photo_two

  def initialize(photo, other_photo)
    @photo = photo
    @other_photo = other_photo
    @photo_one, @photo_two = [photo, other_photo].shuffle
  end

  def as_json(options=nil)
    name = photo.first_name.blank? ? photo.him_her : photo.first_name
    {
      :match_me_id => photo.id,
      :name => name,
      :opposite_sex => other_photo.him_her,
      :other_photo_id => other_photo.id,
      :one => photo_one.image.url,
      :one_interests => (interests = photo_one.interests).blank? ? "" : interests.map(&:title).join(", "),
      :two => photo_two.image.url,
      :two_interests => (interests = photo_two.interests).blank? ? "" : interests.map(&:title).join(", "), 
      :results =>  {
        :yes => 0,
        :no => 0
      },
      :choco => rand(10)
    }
  end

end
