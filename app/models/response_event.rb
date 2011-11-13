class ResponseEvent < ScoreEvent
  def initialize(response, answer)
    super(
      :player_id => answer.game.player_id,
      :event => response,
      :event_at => response.scored_at,
      :answer_count => 0,
      :correct_count => answer.correct? ? 1 : 0,
      :incorrect_count => answer.incorrect? ? 1 : 0
    )
  end
end
