Factory.define :profile do |p|
  p.first_name "first"
  p.location_name "Earth"
  p.birthdate 20.years.ago.to_date
  p.association :player
end
