class CouplesController < ApplicationController

  def index
    @page = (params[:page] || 0).to_i
    @limit = 25
    @start = @page * @limit
    @couple_combos = Combo.inactive_coupled.find(:all, :limit => @limit, :offset => @page * @limit, :joins => [:photo_one, :photo_two], :order => 'combos.yes_percent desc, combos.id desc')
    @couple_combos_count = Combo.inactive_coupled.count
  end

  def show
    @couple_combo = Combo.find(Integer.unobfuscate(params[:id]))
    @ranking = Combo.inactive_coupled.count(:conditions => ["yes_percent > ?", @couple_combo.yes_percent]) + 1
    @yes_lat_lngs = @couple_combo.answers.yes.find(:all, :include => {:game => :player}).map(&:player).compact.select { |p| p.geo_lat.present? && p.geo_lng.present? }.collect { |p| [p.geo_lat, p.geo_lng] }
    @no_lat_lngs = @couple_combo.answers.no.find(:all, :include => {:game => :player}).map(&:player).compact.select { |p| p.geo_lat.present? && p.geo_lng.present? }.collect { |p| [p.geo_lat, p.geo_lng] }
    @couple_friends = CoupleFriend.for_combo(@couple_combo).collect {|combo_friend| combo_friend.other_combo(@couple_combo) }
    unless @couple_friends.empty?
      @couple_friends = (@couple_friends + [@couple_combo]).sort { |a,b| b.yes_percent <=> a.yes_percent }
      @friend_ranking = Combo.inactive_coupled.count(:conditions => ["combo_id in (#{@couple_friends.map(&:id).join(',')}) and yes_percent > ?", @couple_combo.yes_percent]) + 1
    end
    @current_player_page = @current_player == @couple_combo.photo_one.player
  end

  def new
    new_variables
  end

  def create
    if params[:couple].blank?
      new_variables
      flash[:notice] = "Please provide the necessary information below."
      render :action => :new
      return
    end

    if params[:couple][:email].present?
      if User.find_by_email(params[:couple][:email]).present?
        new_variables
        flash[:notice] = "A user with this email already exists. If this is your email please log in to your account."
        render :action => :new
        return
      end
      User.create_email_user(@current_player, params[:couple][:email])
    end

    @current_player.reload
    @current_player.user.inspect
    if @current_player.email.blank?
      new_variables
      flash[:notice] = "Please provide an email address so we can contact you when your results are in."
      render :action => :new
      return
    end

    if params[:couple][:photo_one].blank? || params[:couple][:photo_two].blank?
      new_variables
      flash[:notice] = "Please provide one photo of you and one of your significant other in order to enter the challenge."
      render :action => :new
      return
    end

    photo_one = @current_player.photos.create(params[:couple][:photo_one].merge(:gender => 'm'))
    photo_two = @current_player.photos.create(params[:couple][:photo_two].merge(:gender => 'f'))

    combo = Combo.find_or_create_by_photo_ids(photo_one.id, photo_two.id)
    combo.update_attribute(:active, false)
    response = Response.find_or_create_by_combo_id(combo.id)
    response.update_attributes(:photo_one_answer => "good", :photo_two_answer => "good")

    photo_one.update_attribute(:couple_combo_id, combo.id)
    photo_two.update_attribute(:couple_combo_id, combo.id)
    photo_one.confirm!
    photo_two.confirm!

    unless params[:cf].blank?
      friend_couple_combo = Combo.find_by_id(Integer.unobfuscate(params[:cf]))
      CoupleFriend.create(:combo_id => combo.id, :other_combo_id => friend_couple_combo.id) && friend_couple_combo.present?
    end

    redirect_to couple_path(combo.id.to_obfuscated)
  end

  def add_couple_friend
    other_combo_id = Integer.unobfuscate(params[:id])
    redirect_to couple_path(couple_combos.first.id.to_obfuscated) and return if other_combo_id.nil?
    couple_combos = @current_player.photos.select { |p| p.couple_combo_id.present? }.map(&:couple_combo)
    couple_combos.uniq.each do |couple_combo|
      CoupleFriend.find_or_create_by_combo_ids(couple_combo.id, other_combo_id)
    end
    redirect_to couple_path(couple_combos.first.id.to_obfuscated)
  end

  private
  def new_variables
    @couple_combos = Combo.inactive_coupled.find(:all, :limit => 10, :joins => [:photo_one, :photo_two], :order => 'combos.yes_percent desc').uniq
    @start = 0
  end
end
