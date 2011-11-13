class Admin::PhotosController < AdminController
  def index
    @photo = Photo.new
    @page = (params[:page] || 0).to_i
    limit = 50
    @photos = Photo.find(:all, :order => "id desc", :limit => limit, :offset => @page * limit)
  end

  def show
    @photo = Photo.admin_find(params[:id])
    @combos = @photo.combos.sort { |a,b| b.created_at <=> a.created_at }
  end

  def photo_pairs
    @photo = Photo.admin_find(params[:id])
    @photo_pairs = PhotoPair.where(:photo_id => @photo.id)
  end

  def initial
    @photo = Photo.admin_find(params[:id])
    @candidates = PhotoPair.candidate_pairs_by_profile(@photo, 50)
  end

  def correlations
    @photo = Photo.admin_find(params[:id])
    @photo_pairs = PhotoPair.candidate_pairs_by_correlation(@photo)
    render :photo_pairs
  end

  def new_combos
    @photo = Photo.admin_find(params[:id])
    @combos = Combinator.new_combos(@photo, params[:limit] || 30)
  end

  def crop
    @photo = Photo.admin_find(params[:id])
    if @photo.crop.present?
      @photo.crop.destroy
      @photo.image.reprocess!
    end
    render and return unless request.put?
    @photo.update_attributes(:gender => params[:gender])
    @photo.crop!(params[:crop_spec])
    redirect_to admin_approvals_path
  end

  def good
    good_responses = Response.find(
      :all,
      :conditions => "photo_one_answer in ('good', 'interested', 'uninterested') OR photo_two_answer in ('good', 'interested', 'uninterested')",
      :joins => {:combo => [:photo_one, :photo_two]}
    )
    @best_photos = {}
    good_responses.each do |response|
      ['photo_one', 'photo_two'].each do |method|
        answer = response.send("#{method}_answer")
        if answer == 'good' || answer == 'interested' || answer == 'uninterested'
          photo = response.combo.send(method == 'photo_one' ? 'photo_two' : 'photo_one')
          @best_photos[photo] ||= {}
          @best_photos[photo][answer] ||= 0
          @best_photos[photo][answer] += 1
          @best_photos[photo][:total] ||= 0
          @best_photos[photo][:total] += case answer
            when 'good': 1
            when 'uninterested': 1
            when 'interested': params.include?(:flat) ? 1 : 2
          end
        end
      end
    end
  end
end
