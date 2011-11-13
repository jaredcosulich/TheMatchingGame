class RegistersController < ApplicationController

  MEN_EXAMPLES =   [ [[85, "He"],[[83,36,48], "her"]], [[78, "He"], [[50,81,42], "her"]] ]
  WOMEN_EXAMPLES = [ [[48, "She"],[[54,10,85], "him"]], [[91, "She"],[[44,8,4], "him"]] ]

  def show
    gender = params[:g] || 'u'
    @examples = case gender
      when "m": MEN_EXAMPLES
      when "f": WOMEN_EXAMPLES
      else
        [MEN_EXAMPLES[0], WOMEN_EXAMPLES[1]].shuffle
    end


    redirect_to new_photo_path and return unless @current_player.photos.empty?
  end

  def new
    redirect_to new_photo_path and return if @current_player.profile.present?

    @current_player.build_user if @current_player.user.nil?
    @current_player.user.email = "" if /^fb_/.match(@current_player.user.email)
    @current_player.build_profile if @current_player.profile.nil?
    @photo = @current_player.photos.build
  end

  def create
    photo_params = params[:player].delete(:photo) if params[:player]
    params[:player][:user_attributes][:id] = @current_player.user.id if @current_player.user && params[:player][:user_attributes]
    unless @current_player.update_attributes(params[:player])
      @current_player.build_user if @current_player.user.nil?
      @current_player.build_profile if @current_player.profile.nil?
      @photo = @current_player.photos.build
      render :new
      return
    end
    UserSession.create(@current_player.user)

    begin
      photo = if params[:facebook_photo]
        begin
        facebook_photo = Photo.download_image(params[:facebook_photo])
        rescue Timeout::Error
          flash[:notice] = "Sorry, there was a problem getting that photo from facebook. Please try again, or upload a photo from your computer."
          redirect_to new_photo_path and return
        end
        @current_player.photos.create(:image => facebook_photo)
      else
        @current_player.photos.create(photo_params)
      end
    rescue Photo::UnderAgeException => e
      flash[:notice] = ["You must be over 18 years old to add a photo."]
      redirect_to account_path
      return
    end
    
    if photo.valid?
      redirect_to photo_path(photo)
    else
      flash[:notice] = "Your account was created, but there was a problem with your photo. Please try uploading the photo again and ensure that it is a proper photo."
      redirect_to new_photo_path
    end

  end

  def log_all_requests?
    true
  end

end
