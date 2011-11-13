class MatchMeGame
  attr_reader :game, :photo, :player

  def self.create(photo,player)
    new(photo, player, Game.create!(:player => player))
  end

  def combos(count)
    already_answered_photo_ids = MatchMeAnswer.where("player_id = ? AND target_photo_id = ?", player.id, photo.id).select("other_photo_id").all.map(&:other_photo_id)

    other_person_said_yes = MatchMeAnswer.joins(:target_photo) \
                                   .where("answer = 'y' and other_photo_id = ?", photo.id) \
                                   .where(already_answered_photo_ids.empty? ? nil : "target_photo_id not in (#{already_answered_photo_ids.join(',')})") \
                                   .limit(count) \
                                   .map(&:target_photo) \
                                   .uniq

    priority = Photo.not_college.where("priority_until > now()") \
                    .where("gender = ?", Gendery.opposite(photo.gender)) \
                    .where(already_answered_photo_ids.empty? ? nil : "id not in (#{already_answered_photo_ids.join(',')})") \
                    .limit(2)

    photos_to_match = other_person_said_yes + priority
    if (deficit = count - photos_to_match.length) > 0
      photos_to_match += PhotoPair.candidate_pairs_by_profile(photo, deficit, already_answered_photo_ids + other_person_said_yes.map(&:id)).map(&:other_photo)
    end

    photos_to_match.shuffle.collect do |other_photo|
      MatchMeCombo.new(photo, other_photo)
    end
  end


  private
  def initialize(photo, player, game)
    @photo = photo
    @player = player
    @game = game
  end

end
