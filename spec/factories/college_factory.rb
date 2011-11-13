Factory.sequence :college_name do |n|
  "University #{n}"
end

Factory.sequence :fb_college_id do |n|
  n
end

Factory.define :college do |c|
  c.name {Factory.next :college_name}
  c.fb_id {Factory.next :fb_college_id}
  c.verified true
end
