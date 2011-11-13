require 'spec_helper'

describe FlickrPhoto do
  it "should call the flickr api and determine a large image url" do
    RestClient.should_receive(:post).and_return(flickr_response)

    FlickrPhoto.large_image_url("ignored").should == "http://farm5.static.flickr.com/4009/4441436322_0b90361955_b.jpg"
  end


  def flickr_response
    <<-JSON
      {"sizes":{"canblog":0, "canprint":0, "candownload":1, "size":[{"label":"Square", "width":75, "height":75, "source":"http:\/\/farm5.static.flickr.com\/4009\/4441436322_0b90361955_s.jpg", "url":"http:\/\/www.flickr.com\/photos\/julioenriquez\/4441436322\/sizes\/sq\/", "media":"photo"}, {"label":"Thumbnail", "width":"67", "height":"100", "source":"http:\/\/farm5.static.flickr.com\/4009\/4441436322_0b90361955_t.jpg", "url":"http:\/\/www.flickr.com\/photos\/julioenriquez\/4441436322\/sizes\/t\/", "media":"photo"}, {"label":"Small", "width":"160", "height":"240", "source":"http:\/\/farm5.static.flickr.com\/4009\/4441436322_0b90361955_m.jpg", "url":"http:\/\/www.flickr.com\/photos\/julioenriquez\/4441436322\/sizes\/s\/", "media":"photo"}, {"label":"Medium", "width":"333", "height":"500", "source":"http:\/\/farm5.static.flickr.com\/4009\/4441436322_0b90361955.jpg", "url":"http:\/\/www.flickr.com\/photos\/julioenriquez\/4441436322\/sizes\/m\/", "media":"photo"}, {"label":"Large", "width":"683", "height":"1024", "source":"http:\/\/farm5.static.flickr.com\/4009\/4441436322_0b90361955_b.jpg", "url":"http:\/\/www.flickr.com\/photos\/julioenriquez\/4441436322\/sizes\/l\/", "media":"photo"}, {"label":"Original", "width":"2592", "height":"3888", "source":"http:\/\/farm5.static.flickr.com\/4009\/4441436322_1e6893791c_o.jpg", "url":"http:\/\/www.flickr.com\/photos\/julioenriquez\/4441436322\/sizes\/o\/", "media":"photo"}]}, "stat":"ok"}
    JSON
  end

  describe "set_photo_image" do
    it "should download a large image from flickr and assign to the new Photo" do
      FlickrPhoto.should_receive(:download_image).with("/flickr/url/").and_return(File.new("#{fixture_path}/cow.jpg"))
      
      flickr_photo = FlickrPhoto.create(:flickr_url => "/flickr/url/", :photo => Factory.create(:photo, :gender => "f"))
      flickr_photo.set_photo_image

      flickr_photo.photo.flickr_photo.should == flickr_photo

      flickr_photo.photo.image.url.should_not be_blank
    end

  end
end
