class GameObserver < ActiveRecord::Observer
  observe :game, :answer

  def after_create(thing)
    if thing.is_a?(Game)
      GameEvent.create!(thing)
    else
      GameEvent.find_by_event_id(thing.game.id).update_counts
      thing.game.check_completed
    end
  end

  def self.build_all
    start = Time.now
    GameEvent.destroy_all
    Game.find_each(:include => {:answers => {:combo => :response}}) do |game|
      print "."
      GameEvent.create!(game)
    end
    Time.now - start
  end
end
