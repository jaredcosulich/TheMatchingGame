require 'spec_helper'

describe MatchMeGamesController do

  describe "answers" do
    before :each do
      @player = Factory(:player)
      set_session_for_player(@player)
    end

    it "should create a new MatchMeAnswer with the right info" do
      post :answers, {
        "id"=>"45993",
        "match_me_id"=>"1052",
        "answer"=>{
          "other_photo_id"=>"941",
          "answer"=>"n"
        }
      }

      response.should be_success

      answer = MatchMeAnswer.last
      answer.target_photo_id.should == 1052
      answer.other_photo_id.should == 941
      answer.answer.should == "n"
      answer.game_id.should == 45993
      answer.player_id.should_not be_nil
      answer.player_id.should == @player.id
    end
  end
end
