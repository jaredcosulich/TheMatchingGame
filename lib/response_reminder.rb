class ResponseReminder
  def self.send_reminders(id=nil)
    User.emailable('awaiting_response').where(id.nil? ? nil : ["users.id = ?", id]).includes(:player => :photos).each do |user|
      photos = user.player.photos.select { |p| p.approved? && p.couple_combo_id.nil? }
      photo_photos = {}
      photos.each do |photo|
        combos = photo.ready_for_response.select { |c| !c.active? && c.photo_emailed(photo).blank?}
        combos.each { |c| Combo.update(c.id, "#{c.photo_position_for(photo)}_emailed_at" => Time.new) }
        photo_photos[photo.id] = combos.collect{ |c| c.other_photo(photo) }.map(&:id)
        photo_photos.delete(photo.id) if photo_photos[photo.id].empty?
      end
      Emailing.delay(:priority => 9).deliver("response_reminder", user.id, photo_photos) unless photo_photos.values.flatten.empty?
    end
  end

  def self.missing_reminders
    User.find(:all, :conditions => "email like 'fb_%'").select{|u|u.player.photos.select{|photo| photo.approved?}.present?}.collect do |user|
      photos = user.player.photos.select { |p| p.approved? }
      photo_photos = {}
      photos.each do |photo|
        photo_photos[photo.id] = photo.ready_for_response.select { |c| !c.active? }.collect{ |c| c.other_photo(photo) }.map(&:id)
      end
      all_photos = photo_photos.values.flatten
      if all_photos.empty?
        [user.fb_id, user.player.id]
      else
        emailing = Emailing.create(:user_id => user.id, :email_name => "missing_reminder")
        [user.fb_id, "#{user.player.first_name} there are #{all_photos.length} matches waiting for you at The Matching Game. You can see your matches here: #{emailing.auto_login_path("/account")} . Also, your email was saved incorrectly. You can reset it here: #{emailing.auto_login_path("/account/edit")}"]
      end
    end

  end

  def self.send_other_photo_match_reminders(id=nil)
    User.emailable('awaiting_response').where(id.nil? ? nil : ["users.id = ?", id]).includes(:player => :photos).each do |user|
      photos = user.player.photos.select { |p| p.approved? && p.couple_combo_id.nil? }
      photo_photos = {}
      photos.each do |photo|
        photo_pairs = photo.photo_pairs.
                            other_photo_matches_to_reveal.
                            where("photo_pairs.other_photo_match_revealed_at BETWEEN ? AND ?", 11.hours.ago, Time.new)
        photo_photos[photo.id] = photo_pairs.map(&:other_photo_id)
        photo_photos.delete(photo.id) if photo_photos[photo.id].empty?
      end
      Emailing.delay(:priority => 9).deliver("other_photo_match_reminder", user.id, photo_photos) unless photo_photos.values.flatten.empty?
    end
  end
end

