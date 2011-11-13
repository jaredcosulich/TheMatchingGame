Factory.define :facebook_profile do |p|
  p.fb_info({
    "name"=>"Adam Abrons",
    "relationship_status"=>"Married",
    "timezone"=>"-7",
    "gender"=>"male",
    "id"=>"15700",
    "birthday"=>"11/11/1971",
    "last_name"=>"Abrons",
    "updated_time"=>"2009-04-12T01:42:27+0000",
    "verified"=>"true",
    "link"=>"http://www.facebook.com/abrons",
    "email"=>"abrons@gmail.com",
    "education"=>
      {"0"=>{"school"=>{"name"=>"Harvard University", "id"=>"105930651606"}, "concentration"=>{"0"=>{"name"=>"Fine Arts", "id"=>"109365205763873"}}, "year"=>{"name"=>"1993", "id"=>"115895498421052"}},
       "1"=>{"school"=>{"name"=>"Morgantown High School", "id"=>"107763825919362"}, "year"=>{"name"=>"1989", "id"=>"114810925198328"}}},
    "first_name"=>"Adam"}.to_json
  )
  p.association :player
end
