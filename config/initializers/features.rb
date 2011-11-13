class Features
  cattr_accessor :combos_to_show
  cattr_accessor :challenge_scoring_combos_to_show
  cattr_accessor :challenge_predicted_combos_to_show
  cattr_accessor :max_photos_per_user
  cattr_accessor :coupled_vote_count
end
Features.combos_to_show = 12
Features.challenge_scoring_combos_to_show = 11
Features.challenge_predicted_combos_to_show = 9
Features.max_photos_per_user = 4
Features.coupled_vote_count = 30
