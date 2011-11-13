class College::PhotosController < ApplicationController
  layout "college"

  def index
    @selected_tab = "matches_for_you"

    @photos = @current_player.photos.where("couple_combo_id is null and current_state != 'rejected'")
    @photo = @photos.first

    @matches = @photos.map(&:ready_for_response).flatten.sort_by{|c|c.response.revealed_at}.reverse
  end

  def new
    access_token = session["access_token"]

    @album_data = FacebookProfile.graph_request(access_token, "/me/albums")["data"]
    @photos = []
    @selected_album = params[:album_id].blank? ? @album_data.first : @album_data.detect { |a| a["id"] == params[:album_id] }

    photos_data = FacebookProfile.graph_request(access_token, "/#{@selected_album["id"]}/photos")["data"]
    photos_data.each do |photo_data|
      @photos << [photo_data["images"].last["source"], photo_data["images"].first["source"]]
    end

    render :layout => false
  end

  def create
    if params[:selected_photo].blank?
      flash[:notice] = "Please select a photo."
      redirect_to new_college_photo_path
    end
    facebook_photo = Photo.download_image(params[:selected_photo])
    @current_player.photos.college(@current_player.college_id).approved_or_confirmed.each { |p| p.pause! }
    photo = @current_player.photos.create!(:image => facebook_photo, :college => @current_player.college)
    photo.confirm!
    render :partial => "college/refresh_parent"
  end

end
