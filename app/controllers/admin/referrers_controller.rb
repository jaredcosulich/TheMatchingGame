class Admin::ReferrersController < AdminController
  def index
    @referrer = Referrer.new
    @referrers = Referrer.find(:all, :order => "url asc, id desc")
    @referrals = {}
    @referrers.each do |referrer|
      @referrals[referrer.id] = referrer.referrals.first_time.count(:conditions => date_conditions(params, nil, "referrals"))
    end
  end

  def create
    @referrer = Referrer.create(params[:referrer])
    if @referrer.save
      redirect_to admin_referrers_path
    else
      @referrers = []
      render :index
    end
  end

  def show
    @referrer = Referrer.find(params[:id], :include => :referrals)
    @player_ids = @referrer.referrals.first_time.find(:all, :conditions => date_conditions(params, nil, 'referrals')).map(&:player_id)

    @user_count = User.count(:conditions => "player_id in (#{@player_ids.join(',')})") unless @player_ids.empty?
    @photo_count = Photo.count(:conditions => "player_id in (#{@player_ids.join(',')})") unless @player_ids.empty?
    @approved_photo_count = Photo.count(:conditions => "current_state = 'approved' AND player_id in (#{@player_ids.join(',')})") unless @player_ids.empty?

    @games = Game.find(:all, :select => "id", :conditions => "player_id in (#{@player_ids.join(',')})") unless @player_ids.empty?
    @answer_count = Answer.count(:conditions => "game_id in (#{@games.map(&:id).join(',')})") unless @games.blank?
  end

  def update
    @referrer = Referrer.find(params[:id])
    result = @referrer.update_attributes(params[:referrer])
    if result
      redirect_to admin_referrer_path(@referrer)
    else
      render :show
    end

  end
end
