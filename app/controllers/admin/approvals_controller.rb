class Admin::ApprovalsController < AdminController
  def index
    @photo_reviewal = true
    @unreviewed = Photo.not_college.unreviewed.find(:all, :order => "id asc", :limit => 9)

    @most_recent_photos = Photo.find(:all, :order => "id desc", :limit => 20)
  end

  def bulk
    photos_hash = params[:photos] || {}

    bulk_process(photos_hash) unless photos_hash.empty?

    render :nothing => true
  end

  private
  def bulk_process(photo_states)
    photos = Photo.find(:all, :conditions => "id in (#{photo_states.keys.join(',')})")
    photos.each do |p|
      if photo_states[p.id.to_s].first == 'approved'
        p.approve! unless p.approved?
        p.update_attribute(:bucket, photo_states[p.id.to_s][1])
        if (rotation = photo_states[p.id.to_s][2].to_i) != 0
          p.crop ||= p.create_crop
          p.crop.update_attribute(:rotation, rotation)
          p.image.reprocess!
        end
      elsif photo_states[p.id.to_s].first == 'rejected'
        p.reject!
        p.update_attribute(:rejected_reason, photo_states[p.id.to_s][1])
      end
    end

  end
end
