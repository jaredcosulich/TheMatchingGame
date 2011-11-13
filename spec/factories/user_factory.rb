Factory.sequence :email do |n|
  "person#{n}@example.com"
end

Factory.define :user do |u|
  u.association :player
  u.email {Factory.next :email}
  u.password "password"
  u.password_confirmation "password"
  u.terms_of_service true
  u.last_payment 1.week.ago
end

Factory.define :admin, :parent => :user do |a|
  a.fb_id 15700
end
