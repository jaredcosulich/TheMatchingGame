Factory.define :challenge do |c|
  c.name "new challenge"
  c.association :creator, :factory => :full_player
  c.after_build{|c|c.challenge_players.build(:name => c.creator.full_name, :email => c.creator.email)}
end
