class MatchMeAnswerObserver < ActiveRecord::Observer

  def after_create(match_me_answer)
    MatchMeAnswerObserver.delay.refresh(match_me_answer.id)
  end

  def self.refresh(id)
    match_me_answer = MatchMeAnswer.find(id)
    answer_pair = PhotoPair.create_or_refresh_by_photos_ids(match_me_answer.target_photo_id, match_me_answer.other_photo_id)
    PhotoPair.create_or_refresh_by_photos_ids(match_me_answer.other_photo_id, match_me_answer.target_photo_id)

    if match_me_answer.answer = "y" && answer_pair.other_photo_answer_yes > 0
      combo = Combo.find_or_create_by_photo_ids(answer_pair.photo_id, answer_pair.other_photo_id)
      combo.creation_reason ||= "mutual_match_me"
      combo.active = false
      combo.build_response(:creation_reason => "mutual_match_me") unless combo.response
      combo.save!
    end
  end
end
