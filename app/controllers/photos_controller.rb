class PhotosController < ApplicationController
  before_filter :ensure_registered_user, :except => [:facebook]
  before_filter :load_photo_from_param_or_redirect
  before_filter :set_tab

  def index
    @photos = @current_player.photos.not_college.not_coupled.where("current_state != 'rejected'")
    @photo = @photos.first
    redirect_to root_path and return if @photo.nil?
    
    @page = (params[:page] || 0).to_i
    
    @matches = case params[:t]
      when "good": Combo.matching_full.with_responses_for(@photos, [:good, :interested, :uninterested]).page(@page, 10)
      when "bad": Combo.matching_full.with_responses_for(@photos, [:bad]).page(@page, 10)
      when "possible": PhotoPair.for(@photos).other_photo_matches_to_reveal.map(&:combo).compact
      when "progress": PhotoPair.for(@photos).in_progress.map(&:combo).compact
      else @photos.map(&:ready_for_response).flatten.sort_by{|c|c.response.revealed_at}.reverse
    end

    @selected_subtab = "all"
  end

  def show
    if !@photo.unconfirmed? && @photo.redundant_gender.nil? 
      flash[:notice] = "Please specify your gender."
      redirect_to edit_account_profile_path
      return
    end

    @selected_tab = "account"
    @selected_subtab = "photos"
  end

  def requires_message(requirement_message, action_name)
    return unless action_name == 'new'
    return "#{requirement_message} in order to add your photo."
  end

  def new
    if @current_player.preferred_profile.present?
      @photo = Photo.new(:player => @current_player)
    else
      redirect_to new_register_path(:ref => "new_photo")
    end
  end

  def create
    params[:photo] ||= {}
    if params[:photo].include?(:player)
      @current_player.update_attributes(params[:photo].delete(:player))
    end
    @photo = Photo.new(params[:photo].merge(:player => @current_player))
    begin
      result = @photo.save
    rescue Photo::MaxPhotosException => e
      flash[:notice] = ["You've already uploaded the maximum number of photos."]
    rescue Photo::UnderAgeException => e
      flash[:notice] = ["You must be over 18 years old to add a photo."]
    end
    if result
      redirect_to photo_path(@photo)
    else
      render :new
    end
  end

  def facebook
    facebook_photo = Photo.download_image(params[:facebook_photo])
    photo = Photo.create!({:player => @current_player}.merge(:image => facebook_photo))
    redirect_to photo_path(photo)
  rescue
    flash[:notice] = "Please select one of your Facebook photos or upload another photo."
    redirect_to new_photo_path
  end

  def edit
    unless @photo.unconfirmed? || @photo.rejected?
      flash[:notice] = "This photo has been confirmed and cannot be changed.<br/><br/>You can pause or remove this photo and add another one."
      redirect_to photo_path(@photo)
    end
  end

  def update
    if @photo.unconfirmed? || @photo.rejected?
      result = @photo.update_attributes(params[:photo])
      @photo.resubmit! if @photo.rejected?
      unless result
        render :edit
        return
      end
    else
      flash[:notice] = "This photo has been confirmed and cannot be changed.<br/><br/>You can pause or remove this photo and add another one."
    end
    redirect_to photo_path(@photo)
  end

  def update_player
    success = @current_player.update_attributes(params[:player])
    @current_player.update_interests(params[:interests])
    if success
      flash[:notice] = "Profile Changes Saved Successfully."
    else
      flash[:notice] = @current_player.errors.full_messages
    end
    redirect_to(photo_path(@photo))
  end

  def confirm
    @photo.crop!(params[:crop_spec])
    @photo.confirm! unless @photo.confirmed?
    redirect_to photo_path(@photo)
  end

  def pause
    @photo.pause!
  rescue AASM::InvalidTransition => e
  ensure
    redirect_to photo_path(@photo)
  end

  def resume
    @photo.resume!
  rescue Photo::MaxPhotosException => e
      flash[:notice] = ["You already have the maximum number of photos matching.<br/><br/>Please stop matching one of your other photos to start matching this photo."]
  rescue AASM::InvalidTransition => e
  ensure
    redirect_to photo_path(@photo)
  end

  def remove
    @photo.remove!
    flash[:notice] = "Your photo has been removed."
    redirect_to account_path
  end

  private

  def load_photo_from_param_or_redirect
    return unless params[:id]
    photo_id = params[:id]
    redirect_to @current_player.photos.find(photo_id) and return false if photo_id.to_i > 0
    photo_id = Integer.unobfuscate(photo_id)
    @photo = @current_player.photos.find(photo_id)
  end

  def set_tab
    @selected_tab = "matching"
  end

end
