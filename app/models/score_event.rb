class ScoreEvent < ActiveRecord::Base
  belongs_to :player

  belongs_to :event, :polymorphic => true

  scope :event_ordered, order("event_at asc")
  scope :last_updated, order("updated_at desc").limit(1)


  def score(answer_weight)
    answer_weight.answer_count += answer_count
    answer_weight.correct_count += correct_count
    answer_weight.incorrect_count += incorrect_count
    answer_weight.point_value
  end
end
