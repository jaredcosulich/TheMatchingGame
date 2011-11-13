Factory.define :combo_action do |c|
  c.association :combo, :factory => :female_photo
  c.association :photo, :factory => :combo
end

Factory.define :message, :parent => :combo_action do |m|
  m.action "message"
end

Factory.define :connection, :parent => :combo_action do |m|
  m.action "connection"
end
