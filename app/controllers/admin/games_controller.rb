class Admin::GamesController < AdminController

  def index
    @games = Game.order("id desc").limit(50).includes([{:answers => {:combo => [:photo_one, :photo_two]}}, :player])
  end

end

