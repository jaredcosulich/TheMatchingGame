class Admin::CombosController < AdminController
  def index
    @bubble_combos = ComboScore.find(:all, :order => "score - yes_percent asc", :limit => 50).collect(&:combo).uniq
  end

  def filter_real_real(combos)
    combos.select{ |c|  }.select { |c| c.photo_one.flickr_photo.nil? && c.photo_two.flickr_photo.nil? }
  end

  def great_combos
    @page = (params[:page] || 0).to_i
    @great_combos = Combo.includes(:photo_one, :photo_two).
                          where("yes_count >= 30").
                          where("photos.current_state = 'approved' and photo_twos_combos.current_state = 'approved'").
                          order("yes_percent desc, inactivated_at desc").
                          limit(10).offset(@page * 10)
  end

  def fake_predicted
    @fake_predicted_combos = Combo.fake_predicted([]).order("yes_percent asc")
  end

  def show
    @combo = Combo.full.find(params[:id], :include => {:answers => {:game => {:player => [:user, :player_stat]}}})
  end
end
