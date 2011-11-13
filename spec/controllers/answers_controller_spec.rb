require 'spec_helper'

describe AnswersController do
  before :each do
    ActiveRecord::Observer.with_observers(:game_observer) do
      player = Factory.create(:player)
      set_session_for_player(player)
      @in_play_combo = Factory.create(:answer, :game => Factory.create(:game, :player => player)).combo
      @recent_correct_answer = Factory.create(:answer, :answer => 'n', :player => player, :game => Factory.create(:game, :player => player))
      @bad_match_combo = @recent_correct_answer.combo
      @bad_match_combo.create_response(:photo_one_answer => 'bad')
    end
  end

  describe "show" do
    it "should render recently changed answers" do
      get :show
      response.should be_success
      assigns[:answers].should == [@recent_correct_answer]
    end
  end

  describe "query" do
    render_views

    it "should render partial with correct answers" do
      get :query, :q => 'predicted_correct'
      response.should be_success
      response.body.should include(@bad_match_combo.photo_one.image.url(:thumbnail))
      response.body.should include(@bad_match_combo.photo_two.image.url(:thumbnail))
    end


  end

end
