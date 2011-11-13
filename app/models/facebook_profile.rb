class FacebookProfile < ActiveRecord::Base
  include ProfileBehavior
  belongs_to :player

  def first_name
    get_attribute('first_name')
  end

  def last_name
    get_attribute('last_name')
  end

  def birthdate
    Date.parse(get_attribute('birthday')) unless get_attribute('birthday').nil?
  end

  def sexual_orientation
    's'
  end

  def location_name
    current_location = get_attribute('current_location')
    current_location['name'] if current_location
  end

  def get_attribute(name)
    JSON.parse(fb_info || "{}")[name]
  end

  def merge_fb_info(fb_params={})
    fb_json = JSON.parse(fb_params.to_json)
    self.fb_info = JSON.parse(fb_info || "{}").merge(fb_json).to_json
  end

  def self.get_access_token(code)
    url = URI.parse("https://graph.facebook.com/oauth/access_token?client_id=#{FACEBOOK_APP_ID}&redirect_uri=#{FACEBOOK_CANVAS_PAGE}&client_secret=#{FACEBOOK_APP_SECRET}&code=#{CGI::escape(code)}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')
    tmp_url = url.path+"?"+url.query
    request = Net::HTTP::Get.new(tmp_url)
    response = http.request(request)
    response.body.split("=")[1].split("&")[0]
  end

  def self.graph_request(access_token, query="/me")
    url = URI.parse("https://graph.facebook.com#{query}?access_token=#{CGI::escape(access_token)}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')
    tmp_url = url.path+"?"+url.query
    request = Net::HTTP::Get.new(tmp_url)
    response = http.request(request)
    user_data = response.body
    JSON.parse(user_data)
  end

  def self.find_or_create_college_user(access_token)    
    fb_data = FacebookProfile.graph_request(access_token)

    user = User.includes(:player).where("fb_id = ? OR email = ?", fb_data["id"], fb_data["email"]).first
    if user.nil?
      user = FacebookProfile.create_user_from_fb_data(fb_data)
    else
      college = College.find_or_create_from_fb_location_data(fb_data["location"])
      college = College.find_or_create_from_fb_data(fb_data["education"]) if college.nil?
      user.player.update_attributes(:college => college)
    end

    if user.player.college_photo.nil?
      album_data = FacebookProfile.graph_request(access_token, "/me/albums")["data"]
      album_data.each do |album|
        if album["name"] == "Profile Pictures"
          photos_data = FacebookProfile.graph_request(access_token, "/#{album["id"]}/photos")["data"]
          facebook_photo = Photo.download_image(photos_data.first["images"].first["source"])
          photo = Photo.create!(:player => user.player, :image => facebook_photo, :college => user.player.college)
          photo.confirm!
        end
      end
    end
    user
  end

  def self.create_user_from_fb_data(fb_data)
    college = College.find_or_create_from_fb_location_data(fb_data["location"])
    college = College.find_or_create_from_fb_data(fb_data["education"]) if college.nil?
    player = Player.create(
      :gender => fb_data["gender"] == "male" ? "m" : "f",
      :college => college
    )
    FacebookProfile.create(
      :fb_info => fb_data.to_json,
      :player => player
    )
    User.create(
      :fb_id => fb_data["id"],
      :email => fb_data["email"],
      :password => password = UUID.generate,
      :password_confirmation => password,
      :terms_of_service => true,
      :player => player
    )
  end

#  {"data"=>
#  [{"name"=>"Profile Pictures",
#    "cover_photo"=>"10150188222778581",
#    "from"=>{"name"=>"Jared Cosulich", "id"=>"580888580"},
#    "id"=>"428544853580",
#    "created_time"=>"2010-09-08T19:35:42+0000",
#    "type"=>"profile",
#    "count"=>2,
#    "updated_time"=>"2011-05-19T15:50:03+0000",
#    "privacy"=>"friends-of-friends",
#    "link"=>
#     "http://www.facebook.com/album.php?fbid=428544853580&id=580888580&aid=211205"},
#   {"name"=>"Wall Photos",
#    "cover_photo"=>"175196378580",
#    "from"=>{"name"=>"Jared Cosulich", "id"=>"580888580"},
#    "id"=>"175196373580",
#    "created_time"=>"2009-11-14T01:38:44+0000",
#    "type"=>"wall",
#    "count"=>1,
#    "updated_time"=>"2009-11-14T01:38:44+0000",
#    "privacy"=>"friends",
#    "link"=>
#     "http://www.facebook.com/album.php?fbid=175196373580&id=580888580&aid=124001"}],
# "paging"=>
#  {"previous"=>
#    "https://graph.facebook.com/me/albums?access_token=104015342967729|2.AQBITVKPoYrx1xWx.3600.1314147600.1-580888580|BD81ptyuN1RcHGd8Dx2WPudXgls&limit=25&since=1283974542",
#   "next"=>
#    "https://graph.facebook.com/me/albums?access_token=104015342967729|2.AQBITVKPoYrx1xWx.3600.1314147600.1-580888580|BD81ptyuN1RcHGd8Dx2WPudXgls&limit=25&until=1258162724"}}


#    FB.api('/me/albums', function(response) {
#        for (album in response.data) {
#          if (response.data[album].name == "Profile Pictures") {
#            FB.api(response.data[album].id + "/photos", function(response) {
#              image = response.data[0].images[0].source;
#            });
#          }
#        }
#      });


end
