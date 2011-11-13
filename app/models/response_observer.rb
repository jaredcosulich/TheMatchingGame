class ResponseObserver < ActiveRecord::Observer

  def after_update(response)
    PhotoPair.refresh_by_combo_id(response.combo_id)
    ResponseObserver.delay(:priority => 9).rescore(response.id)
  end

  def self.rescore(response_id)
    response = Response.find(response_id)
    ResponseEvent.destroy_all(["event_id = ?", response_id])

    if response.verified?
      response.combo.answers.full.predicted.find(:all, :include => :game).each do |answer|
        ResponseEvent.new(response, answer).save!
      end

      response.combo.answers.full.existing.each do |answer|
        GameEvent.find_by_event_id(answer.game_id).update_counts
      end
    end
  end

  def self.build_all
    start = Time.now
    ResponseEvent.destroy_all
    Response.find(:all, :include => {:combo => :answers}).each do |response|
      print "."
      if response.verified?
        response.combo.answers.full.predicted.each do |answer|
          ResponseEvent.new(response, answer).save!
        end
      end      
    end
    Time.now - start
  end
end
