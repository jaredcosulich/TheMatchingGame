class Admin::SampleGamesController < AdminController


  def show
    @game = Game.new(:player => find_or_new_player)
    @combos = @game.combos((params[:count] || Features.combos_to_show).to_i)
  end

  def challenge
    player = find_or_new_player
    challenge = Challenge.new(:creator => player)
    challenge.select_challenge_combos
    @combos = challenge.combos_with_predicted(@game = Game.new(:player => player))
    render :action => :show
  end

  private
  def find_or_new_player
    params.include?(:id) ? Player.find(params[:id]) : Player.new
  end
end
