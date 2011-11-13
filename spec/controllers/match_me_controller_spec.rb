require 'spec_helper'

describe MatchMeController do

  describe "show" do
    before :each do
      @match_me_referrer = Factory(:referrer, :url => "Match Me", :uid => "match_me")
      @target_photo = Factory(:registered_photo)
    end

    it "should create a player with a referral for match_me if they are not the target photo" do
      get "show", :id => @target_photo.id.to_obfuscated

      player = Player.last
      player.referrer.should == @match_me_referrer
    end

    it "should create a player with a referral for match_me if they are not the target photo" do
      set_session_for_player(@target_photo.player)
      get "show", :id => @target_photo.id.to_obfuscated

      player = Player.last
      player.should == @target_photo.player
      player.referrer.should be_nil
    end
  end

  describe "index" do
    it "should show the current user's first photo" do
      photo  = Factory(:registered_photo)
      player = photo.player
      set_session_for_player(player)
      get :index
      response.should be_success
      assigns(:photo).should == photo
    end

    it "should redirect the user to the photo upload page if they don't have any photos" do
      player = Factory(:player)
      set_session_for_player(player)
      get :index
      response.should redirect_to(new_photo_path)
    end
  end

end
