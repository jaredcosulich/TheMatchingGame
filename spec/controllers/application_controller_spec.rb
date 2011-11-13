require 'spec_helper'

class TestsController < ApplicationController
  before_filter :ensure_registered_user, :only => :registered

  def index
    head 200
  end

  def registered
    head 200
  end
end


describe TestsController do
  it "should new a player if player cookie not set" do
    with_test_routes do
      get :index
      session[:player_id].should be_nil
      assigns[:current_player].should be_new_record
      assigns[:current_player].user.should be_nil
    end
  end

  it "should find the user from the cookie and set current user" do
    with_test_routes do
      player = Factory.create(:player)

      set_session_for_player player

      get :index
      session[:player_id].should == player.id
      assigns[:current_player].should == player
      assigns[:current_player].user.should be_nil
    end
  end

  describe "with referral" do
    before :each do
      @referrer = Factory.create(:referrer, :uid => "asd")
    end

    it "should set a cookie on get" do
      with_test_routes do
        get :index, :r => "asd"

        cookies['r'].should == "asd"
        @referrer.referrals.count.should == 0
        Player.count.should == 0
        session[:player_id].should be_nil
        assigns[:current_player].should be_new_record

      end
    end

    it "should save the user if the cookie is present" do
      with_test_routes do

        request.cookies['r'] = "asd"

        get :index

        player = Player.last
        assigns[:current_player].should == player
        @referrer.referrals.count.should == 1
        @referrer.players.should == [player]
      end
    end

  end

  pending "facebook" do
#    include Facebooker::Rails::TestHelpers

    before :each do
      @unlinked_player = Factory.create(:player)
      @mock_fb_id = 15700
      @linked_player = Factory.create(:user, :fb_id => @mock_fb_id).player
    end


    describe "uid from facebook matches existing player uid" do
      it "should log the person in (and maybe update)" do
        with_test_routes do
          get :index, facebook_params(:fb_sig_canvas_user => @mock_fb_id)

          assigns[:current_player].should == @linked_player
          session[:player_id].should == @linked_player.id
        end
      end

      it "should replace an existing unlinked but different player_id" do
        with_test_routes do
          session[:player_id] = @unlinked_player.id

          get :index, facebook_params(:fb_sig_user => @mock_fb_id)

          assigns[:current_player].should == @linked_player
          session[:player_id].should == @linked_player.id
        end
      end

      it "should replace an existing linked with a different linked player_id" do
        with_test_routes do
          another_linked_player = Factory.create(:user, :fb_id => 2893712).player
          session[:player_id] = another_linked_player.id

          get :index, facebook_params(:fb_sig_user => @mock_fb_id)

          assigns[:current_player].should == @linked_player
          session[:player_id].should == @linked_player.id
        end
      end
    end


    describe "uid from facebook does not match existing player uid" do

      it "should create a new player and new user if there is no player id in the session" do
        with_test_routes do
          Player.count.should == 2
          get :index, facebook_params(:fb_sig_user => 198219)
          Player.count.should == 3
          created = Player.last
          created.user.fb_id.should == 198219
          assigns[:current_player].should == created
          session[:player_id].should == created.id
        end
      end

      it "should link the fb uid to the player in the session if there is one" do
        with_test_routes do
          session[:player_id] = @unlinked_player.id

          Player.count.should == 2
          get :index, facebook_params(:fb_sig_user => 198219)
          Player.count.should == 2
          @unlinked_player.reload
          @unlinked_player.user.fb_id.should == 198219
          assigns[:current_player].should == @unlinked_player
          session[:player_id].should == @unlinked_player.id
        end
      end

      it "should create a new player if the uid from facebook does not match the uid in from the player in the session" do
        with_test_routes do
          session[:player_id] = @linked_player.id

          Player.count.should == 2
          get :index, facebook_params(:fb_sig_user => 198219)
          Player.count.should == 3
          another_linked_player = Player.last
          another_linked_player.user.fb_id.should == 198219
          assigns[:current_player].should == another_linked_player
          session[:player_id].should == another_linked_player.id
        end
      end

    end
  end

  describe "ensure_registered_user" do
    it "should redirect to login and set a cookie if not logged in" do
      with_test_routes do
        get :registered
        response.should redirect_to(new_session_path)
        cookies['post_login_path'].should == "/tests/registered"
      end
    end

    it "should work if logged in" do
      with_test_routes do
        login_as Factory.create(:user)
        get :registered
        response.should be_success
      end
    end

  end
end


def with_test_routes
  with_routing do |set|
    set.draw do
      resources :tests do
        collection do
          get :registered          
        end
      end
      resource :session
    end
    yield
  end
end
