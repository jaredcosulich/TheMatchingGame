Factory.define :player do |p|
  p.gender "m"
end

Factory.define :registered_player, :parent => :player do |r|
  r.after_create {|p| Factory(:user, :player => p)}
end

Factory.define :full_player, :parent => :registered_player do |r|
  r.after_create {|p| Factory(:profile, :player => p)}
end
