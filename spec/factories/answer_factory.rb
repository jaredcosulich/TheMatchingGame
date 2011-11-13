Factory.define :answer do |a|
  a.association :combo
  a.association :game
  a.after_build{ |a| a.player_id = a.game.player_id if a.player_id.nil? }
  a.answer "y"
end
