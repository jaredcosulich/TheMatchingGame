module AdminHelper
  def thumbnail(photo)
    photo_link(photo)
  end

  def photo_link(photo, size = :thumbnail)
    link_to(image_tag(photo.image.url(size), :title => "#{photo.id} - #{photo.title} - #{photo.current_state}"), admin_photo_path(photo))
  end
end
