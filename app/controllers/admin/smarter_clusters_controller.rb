class Admin::SmarterClustersController < AdminController

  helper "admin/clusters"

  def index
    @correlated_photos = Photo.find(:all, :conditions => "current_state='approved'", :order => "id desc")
    @photo_map = @correlated_photos.inject({}) { |map, photo| map[photo.id] = photo ; map}
    @combo_finder = ComboFinder.new
    render :template => "admin/clusters/index"
  end

  def show
    @photo = Photo.admin_find(params[:id])

    @combos = @photo.combos.select { |c| c.total_votes > Correlator.vote_threshold }

    @other_combos = {}
    @combos.each do |combo|
      other_photo_id = combo.other_photo_id(@photo.id)
      @other_combos[combo.id] = Photo.find(other_photo_id).combos.select { |c| c.total_votes > Correlator.vote_threshold }
    end

    @correlations = ComboScore.correlations(@photo.id, 75, 75).collect{|cs|[cs.other_photo_id, "TBD"]}
    @existing_suggestions, @not_existing_suggestions = @photo.partitioned_suggestions

    @combo_finder = ComboFinder.new

    render :template => "admin/clusters/show"
  end

  def delta
    qualifier = params[:d] == "worse" ? "ASC" : "DESC"
    @delta_scores = ComboScore.find(:all, :joins => {:combo => :response}, :limit => 40, :order => "(score - combo_scores.yes_percent) #{qualifier}, combo_id desc")
  end


  class ComboFinder
    def find_combo(photo_id, other_photo_id)
      Combo.find_by_photo_ids(photo_id, other_photo_id)
    end
  end
end
