Factory.define :combo do |c|
  c.association :photo_one, :factory => :male_photo
  c.association :photo_two, :factory => :female_photo
  c.after_create {|c| ComboScore.find_all_by_combo_id(c.id).each { |cs| cs.update_attributes(:score => c.yes_percent, :yes_percent => c.yes_percent)} }
end
