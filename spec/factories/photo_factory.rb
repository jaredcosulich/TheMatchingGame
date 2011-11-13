Factory.define :photo do |p|
  p.gender "m"
  p.bucket 5
  p.association :player
  p.image_file_name "image_file_name"
  p.image_content_type "image/png"
end

Factory.define :registered_photo, :parent => :photo do |p|
  p.association :player, :factory => :registered_player
end

Factory.define :college_photo, :parent => :registered_photo do |p|
  p.college_id 1
  p.after_create {|photo| photo.player.update_attribute(:college_id, 1)}
end

Factory.define :confirmed_photo, :parent => :photo do |p|
  p.current_state 'confirmed'
end

Factory.define :female_photo, :parent => :registered_photo do |p|
  p.gender "f"
  p.current_state 'approved'
end

Factory.define :male_photo, :parent => :registered_photo do |p|
  p.current_state 'approved'
end

Factory.define :not_connectable_photo, :parent => :female_photo do |p|
  p.after_create {|photo| photo.player.update_attribute(:connectable, false)}
end
