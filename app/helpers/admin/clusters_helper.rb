module Admin::ClustersHelper

  def css_class(combo)
    case combo.yes_percent
      when  0...40: "bad"
      when 40...60: "possible"
      when 60...80: "good"
      when 80..100: "great"
    end
  end

  def alt_text(combo)
    return <<-text
      #{combo.id} (#{combo.photo_one_id}, #{combo.photo_two_id}):
      Votes: #{combo.yes_count + combo.no_count} (#{combo.yes_count}, #{combo.no_count}) -
      Yes Percent: #{combo.yes_percent}
    text
  end

  def other_photo_tag(combo, other_photo, size)
    return if other_photo.nil?
    image_tag(other_photo.image.url(size), :class => "#{css_class(combo)} #{dom_id(other_photo)}", :alt => alt_text(combo), :title => alt_text(combo), :path => admin_cluster_path(other_photo))
  end

end
