class Admin::ClustersController < AdminController

  def index
    photos = Photo.find(:all, :conditions => "current_state='approved'", :order => "id desc")
    @photo_map = photos.inject({}) { |map, photo| map[photo.id] = photo ; map}
    @combo_finder = correlator = Correlator.new
    @correlated_photos = photos.collect{|photo| CorrelatedPhoto.new(photo, correlator)}
  end

  def show
    @photo = Photo.admin_find(params[:id])

    @correlator = @combo_finder = Correlator.new

    @combos = @correlator.combos[@photo.id].select { |c| c.total_votes > Correlator.vote_threshold }

    @other_combos = {}
    @combos.each do |combo|
      other_photo_id = combo.other_photo_id(@photo.id)
      @other_combos[combo.id] = @correlator.combos[other_photo_id].select { |c| c.total_votes > Correlator.vote_threshold }
    end

    @correlations = @correlator.correlations[@photo.id].to_a.sort{ |a,b| b[1] <=> a[1] }
    @existing_suggestions = @correlator.existing_suggestions[@photo.id]
    @not_existing_suggestions = @correlator.not_existing_suggestions[@photo.id]
  end

  class CorrelatedPhoto
    attr_accessor :photo
    delegate :id, :image, :to => :photo

    def initialize(photo, correlator)
      @photo = photo
      @correlator = correlator
    end

    def correlated_photo_ids
      @correlator.correlations[photo.id].keys
    end

    def partitioned_suggestions
      [@correlator.existing_suggestions[@photo.id], @correlator.not_existing_suggestions[@photo.id]]
    end

  end

end
