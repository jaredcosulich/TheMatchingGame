class Interest < ActiveRecord::Base
  belongs_to :player
  belongs_to :club
  before_save :set_club
  after_save :set_other_clubs
  before_destroy :decrement_club_count

  def set_club
    self.club_id = nil if title != title_was
    if club_id.nil?
      clubbed_interest = Interest.where("lower(title) = ? and club_id is not null", title.downcase).select("club_id").first
      club_id = clubbed_interest.try(:club_id) || Club.where("title = ? OR permalink = ?", title.downcase, PermalinkFu.escape(title)).select("id").first.try(:id)
      self.club_id = club_id unless club_id.nil?
    end
  end

  def set_other_clubs
    if club.present?
      Interest.connection.update("update interests set club_id = #{club_id} where lower(title) = '#{title.downcase.gsub(/[']/, '\'\'')}' OR lower(title) = '#{club.title.gsub(/[']/, '\'\'')}' and club_id is null")
      club.update_attributes(:interests_count => Interest.where("club_id = ?", club_id).count)
    end  
  end

  def decrement_club_count
    club.update_attributes(:interests_count => club.interests_count - 1) if club
  end
end
