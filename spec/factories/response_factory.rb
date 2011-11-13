def ensure_user(player)
  unless player.user.present?
    Factory.create(:user, :player => player)
    player.reload
  end
end


Factory.define :response do |r|
  r.association :combo
  r.revealed_at {Time.now}
  r.after_build do |response|
    response.combo.reload
    ensure_user(response.combo.photo_one.player)
    ensure_user(response.combo.photo_two.player)
  end
end

Factory.define :good_response, :parent => :response do |r|
  r.photo_one_answer "good"
  r.photo_two_answer "good"
  r.photo_one_rating 8
  r.photo_two_rating 7
  r.after_build{|r|r.combo.update_attribute(:active, false)}
end

Factory.define :bad_response, :parent => :response do |r|
  r.photo_one_answer "bad"
  r.photo_one_rating 3
  r.after_build{|r|r.combo.update_attribute(:active, false)}
end
