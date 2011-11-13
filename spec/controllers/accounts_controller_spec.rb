require 'spec_helper'

describe AccountsController do

  describe "create" do
    describe "with player" do
      before(:each) do
        @player = Factory.create(:player)
        set_session_for_player(@player)
        post :create, :player => {:user_attributes => {:email => "test@test.com", :password => "12345", :password_confirmation => "12345", :terms_of_service => "1"}}
        @user = User.last
      end

      it "should redirect to account page" do
        response.should redirect_to(account_path)
      end

      it "should create a user and set the current_player to that user" do
        @user.player.should == @player
      end

    end

    describe "without player" do
      before :each do
        post :create, :player => {:user_attributes => {:email => "test@test.com", :password => "12345", :password_confirmation => "12345", :terms_of_service => "1"}}

      end
      it "should handle a new, but not saved user" do
        response.should redirect_to(account_path)
        user = User.last
        user.email.should == "test@test.com"
      end
    end

    describe "empty" do
      it "should not not blow up" do
        post :create
        response.should render_template(:new)
      end
    end

    describe "json" do
      it "should create a user and profile for the player" do
        player = Factory.create(:player)
        set_session_for_player(player)
        post :create, :format => "json", :player => {:user_attributes => {:email => "test@test.com"}, :profile_attributes => {:first_name => "Joe", :last_name => "Joel"}}

        player.reload
        player.user.email.should == "test@test.com"

        player.preferred_profile.first_name.should == "Joe"
      end
    end
  end

  describe "show" do
    render_views
    before :each do
      @player = set_session_for_player(Factory.create(:player))
    end

    it "should work with anonymous" do
      get :show
      response.should redirect_to leaderboard_games_path
    end

    it "should work with anonymous with photos" do
      photo = Factory.create(:photo, :player => @player)
      get :show
      response.body.should include(photo_path(photo))
    end

    it "should work with registered but no photos" do
      login_as Factory.create(:user, :player => @player)
      get :show
      response.body.should redirect_to leaderboard_games_path
    end
  end

  describe "edit" do
    it "should work" do
      login_as Factory.create(:user)
      get :edit
    end
  end

  describe "update" do
    before(:each) do
      @player = Factory.create(:registered_player)
      set_session_for_player(@player)
    end

    describe "with sending a profile" do
      before(:each) do
        post :update, :player => {
          :user_attributes => {
            :id => @player.user.id,
            :email => "test1@test.com",
            :password => "12345",
            :password_confirmation => "12345",
            :terms_of_service => "1"
          }, :gender => "f",
          :profile_attributes => {
            :first_name => "test",
            :last_name => "test",
            :location_name => "Concord, MA",
            :birthdate => 20.years.ago
          }
        }

        response.should redirect_to(account_path)
        @player.reload
      end

      it "should update the player" do
        @player.gender.should == 'f'
      end

      it "should update the user" do
        @player.user.email.should == 'test1@test.com'
      end

      it "should create the profile" do
        @player.profile.first_name.should == 'test'
        @player.profile.last_name.should == 'test'
      end

    end

    describe "without sending a profile" do
      before(:each) do
        post :update, :player => {
          :user_attributes => {
            :id => @player.user.id,
            :email => "test1@test.com",
            :password => "12345",
            :password_confirmation => "12345",
            :terms_of_service => "1"
          }, :gender => "f"
        }
        response.should redirect_to(account_path)
        @player.reload
      end

      it "should update the player" do
        @player.gender.should == 'f'
      end

      it "should update the user" do
        @player.user.email.should == 'test1@test.com'
      end

      it "should not create a profile" do
        @player.profile.should be_nil
      end
    end

    describe "updated spoofing another users id" do
      it "should not update the other user" do
        innocent_user = Factory.create(:user, :email => "innocent@example.com")
        spoofing_user = Factory.create(:user, :email => "spoofing@example.com")

        login_as(spoofing_user)

        post :update, :player => {
          :user_attributes => {
            :id => innocent_user.id,
            :email => "fake@example.com",
            :password => "12345",
            :password_confirmation => "12345",
            :terms_of_service => "1"
          }, :gender => "f"
        }
        response.should redirect_to(account_path)

        innocent_user.reload.email.should == "innocent@example.com"
        spoofing_user.reload.email.should == "fake@example.com"
      end
    end

    describe "deleting account" do
      it "should set set deleted info, remove your photos, log you out, and redirect to front page" do
        user = @player.user
        photo = Factory(:confirmed_photo, :player => @player)
        original_email = user.email
        post :update, :player => {
          :user_attributes => {
            :id => user.id,
            :email => "xxx#{original_email}",
            :deleted_at => Time.new,
            :deleted_reason => "Because this site sucks."
          }
        }

        response.should redirect_to(root_path)

        session["player_id"].should be_nil

        deleted_user = User.unscoped.find(user.id)
        deleted_user.email.should_not == original_email
        deleted_user.email.should =~ /#{original_email}/
        deleted_user.deleted_at.should_not be_nil
        deleted_user.deleted_reason.should_not be_nil

        photo.reload.should be_removed

        user.reload.should be_nil
      end
    end
  end
end
