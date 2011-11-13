class FlickrPhoto < ActiveRecord::Base
  belongs_to :photo, :dependent => :destroy

  FLICKR_KEY = "f1a6a734049afbfedfb45d4fab710cf2"


  def set_photo_image
    photo.update_attribute(:image, FlickrPhoto.download_image(flickr_url))
  end

  def self.download_image(flickr_url)
    open(URI.parse(large_image_url(flickr_url)))
  end

  def self.large_image_url(flickr_url)
    method = "http://api.flickr.com/services/rest/"

    photo_id = flickr_url.split(/\//).compact.last

    response = RestClient.post method, :method => "flickr.photos.getSizes", :api_key => FLICKR_KEY, :photo_id => photo_id, :format => :json, :nojsoncallback => 1
    size_map = {}
    json = JSON.parse(response)
    if json['stat'] == 'fail'
      raise json['message']
    else
      JSON.parse(response)['sizes']['size'].each { |info| size_map[info['label'].downcase] = info['source'] }
    end
    size_map['large'] || size_map['original']
  end

end
