class Club < ActiveRecord::Base
  include Permalinkable

  has_many :interests
  has_many :players, :through => :interests

  scope :popular, order("interests_count desc")
  scope :alphabetical, order("title asc")
  scope :trending, lambda { |limit|
    trending_sql = <<-sql
      SELECT club_id, count(id)
      FROM interests
      WHERE created_at BETWEEN '#{1.month.ago}' AND '#{Time.new}'
      GROUP BY club_id
      ORDER by 2 desc
      LIMIT #{limit}
    sql

    info = connection.select_values(trending_sql).compact
    where("id in (#{info.join(",")})")
  }
  scope :random, order("random()")

  def candidate_pairs_by_profile(reference_photo, limit = 20, seen_player_ids = [])
    good_candidate_ids = players.joins(:photos).
                              select("players.id").
                              where("photos.current_state = 'approved'").
                              where("players.gender = ?", Gendery.opposite(reference_photo.gender)).
                              where(@highlighted_player.present? ? "players.id != #{@highlighted_player.id}" : nil).
                              where(seen_player_ids.blank? ? nil : "players.id not in (#{seen_player_ids.join(',')})").
                              order("random()").limit(500).uniq.map(&:id)
    return [] if good_candidate_ids.empty?
    candidate_photos = Photo.where("player_id in (#{good_candidate_ids.join(",")})").
                             includes(:player => [:user, :preferred_profile, :profile, :facebook_profile, :clubs]).
                             approved.
                             not_coupled

    existing_players = {}
    unique_candidates = candidate_photos.select do |candidate|
      if existing_players[candidate.player_id]
        false
      else
        existing_players[candidate.player_id] = true;
      end
    end

    sorted_pairs = unique_candidates.collect do |candidate|
      pair = PhotoPair.new(:photo => reference_photo, :other_photo => candidate)
      pair.lookup_stats
      pair
    end.sort_by(&:score)

    sorted_pairs[0...limit]
  end

  def title_with_count
    "#{title} (#{interests_count})"
  end

  def combine_club(to_remove_club_id)
    to_remove_club = Club.includes(:interests).find(to_remove_club_id)
    to_remove_club.interests.each { |i| i.update_attributes(:club_id => id) }
    to_remove_club.destroy
    update_attributes(:interests_count => Interest.where("club_id = ?", id).count)
  end
end
