class GameEvent < ScoreEvent
  def initialize(game)
    super(count_attributes(game))
  end

  def update_counts
    update_attributes(count_attributes(event))
  end

  def count_attributes(game)
    answer_count = 0
    correct_count = 0
    incorrect_count = 0
    game.answers.full.each do |a|
      answer_count += 1
      correct_count += 1 if a.existing_correct?
      incorrect_count += 1 if a.existing_incorrect?
    end
    {:player => game.player, :event => game, :event_at => game.scored_at, :answer_count => answer_count, :correct_count => correct_count, :incorrect_count => incorrect_count}

  end
end
