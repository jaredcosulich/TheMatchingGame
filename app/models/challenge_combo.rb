class ChallengeCombo < ActiveRecord::Base
  belongs_to :challenge
  belongs_to :combo

  scope :full, includes(:combo => [:photo_one, :photo_two])
  scope :with_combo, includes(:combo)
end
