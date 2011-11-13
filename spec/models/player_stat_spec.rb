require 'spec_helper'

describe PlayerStat do

  describe "score_history" do
    before :each do
      @player = Factory.create :player

      @good_training_combo = Factory.create(:response, :photo_one_answer => "good", :photo_two_answer => "good").combo
      @bad_training_combo = Factory.create(:response, :photo_one_answer => "bad").combo
      @predicting_combo = Factory.create(:combo)

      @game_one = Factory.create(:game, :player => @player)
      Factory.create(:answer, :game => @game_one, :combo => @good_training_combo, :answer => "y")
      Factory.create(:answer, :game => @game_one, :combo => @predicting_combo, :answer => "y")

      @game_two = Factory.create(:game, :player => @player)
      Factory.create(:answer, :game => @game_two, :combo => @bad_training_combo, :answer => "y")

      Factory.create(:response, :combo => @predicting_combo, :photo_one_answer => "bad")

      @game_three = Factory.create(:game, :player => @player)
      Factory.create(:answer, :game => @game_three, :answer => "n")
    end

    it "should provide a score_history containing score_events" do
      score_history = @player.current_stat.score_history
      
      score_history.map(&:score).should == [0, 79, 20, -20, -25]
      score_history.map(&:title).should == ["Game", "Game", "Game", "Response", "Game"]

    end
  end
end
