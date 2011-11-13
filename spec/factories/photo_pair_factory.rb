Factory.define :photo_pair do |c|
  c.association :photo, :factory => :male_photo
  c.association :other_photo, :factory => :female_photo
end
