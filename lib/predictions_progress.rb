class PredictionsProgress
  def self.send_progress_report(days_to_report, id=nil)
    User.emailable("prediction_progress").where(id.nil? ? nil : ["users.id = ?", id]).includes(:player => :photos).each do |user|
      next unless user.player.photos.empty?
      responded_to = user.player.prediction_progress(days_to_report).select { |c| c.verified? }
      next if responded_to.empty?
      Emailing.delay(:priority => 8).deliver("prediction_progress", user.id, responded_to.map(&:id)) unless responded_to.empty?
    end

  end
end
