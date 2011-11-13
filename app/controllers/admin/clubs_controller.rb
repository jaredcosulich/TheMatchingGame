class Admin::ClubsController < AdminController

  def index
    @unclubbed_interest = Interest.where("club_id is null").first
    render and return if @unclubbed_interest.nil?
    
    @selected_club = Club.find_by_id(params[:club_id]) if params[:club_id].present?

    @possible_matches = []
    @unclubbed_interest.title.split(/\s/).each do |word|
      first_letters = word[0..2].downcase.gsub(/[']/, '\'\'')
      @possible_matches += Club.where("title like '%#{first_letters}%'").limit(10)
    end
  end

  def set_club
    interest = Interest.find(params[:id])
    interest.update_attributes(params[:interest])
    flash[:notice] = "Interest #{interest.title} assigned to club #{params[:title]}."
    redirect_to admin_clubs_path
  end

  def create
    if (club = Club.find_by_title(params[:club][:title])).nil?
      club = Club.create!(params[:club])
    end
    redirect_to admin_clubs_path(:club_id => club.id)
  end

end
