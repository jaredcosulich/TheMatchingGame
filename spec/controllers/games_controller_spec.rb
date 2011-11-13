require 'spec_helper'

describe GamesController do

  describe "create" do
    describe "existing player" do
      before :each do
        @player = Factory.create(:player)
        set_session_for_player @player
      end

      it "should create a new game and redirect you to it" do
        post :create
        created = Game.find(:last)
        response.should redirect_to(game_path(created))
        created.player.should == @player
      end

      it "should create a new game and pass by the id if request is an ajax request" do
        post :create, :format => 'json'
        created = Game.find(:last)
        response.body.should == "{\"id\":#{created.id}}"
        response.header["Content-Type"].should == "application/json; charset=utf-8"
        created.player.should == @player
      end

      it "should record location attributes on player if passed uo" do
        post :create, :format => 'json', :location => {:address => {:city => "San Francisco", :region => "CA", :country => "USA"}, :latitude => "37.775", :longitude =>   "-122.419"}
        created = Game.find(:last)
        created.player.should == @player
        created.player.geo_name.should == "San Francisco, CA, USA"
        created.player.geo_lat.should == 37.775
        created.player.geo_lng.should == -122.419
      end
    end

    describe "new player" do
      before :each do
        set_session_for_player nil
      end

      it "should create a new game with a blank player if no current player exists" do
        post :create, :format => 'json'
        created = Game.find(:last)
        response.body.should == "{\"id\":#{created.id}}"
        created.player.should_not be_nil
        session['player_id'].should == created.player.id
      end

      it "should record location attributes on player if passed up" do
        post :create, :format => 'json', :location => {:address => {:city => "San Francisco", :region => "CA", :country => "USA"}, :latitude => "37.775", :longitude =>   "-122.419"}
        created = Game.find(:last)
        player =  created.player
        player.geo_name.should == "San Francisco, CA, USA"
        player.geo_lat.should == 37.775
        player.geo_lng.should == -122.419
      end

    end
  end
end
