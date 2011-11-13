require 'spec_helper'

describe ProfilesController do
  describe "facebook" do
    before :each do
      @player = Factory.create(:user, :fb_id => 100001004109730, :email => "fb_100001004109730@thematchinggame.com").player
      set_session_for_player(@player)
    end

    it "should update location and sex" do
      @player.preferred_profile.should be_nil
      @player.facebook_profile.should be_nil
      post :facebook, :fb_info => {"id"=>"100001004109730", "sex"=>"female", "current_location"=>{"city"=>"XXXX", "name" => "San Francisco, California"}}
      @player.reload.location_name.should == "San Francisco, California"
      @player.preferred_profile.should == @player.facebook_profile
      @player.gender.should == "f"
    end

    it "should update name and email" do
      post :facebook, :fb_info => {"name"=>"Jane Abrons", "id"=>"100001004109730", "timezone"=>"-7", "last_name"=>"Abrons", "birthday"=>"11/11/1971", "link"=>"http://www.facebook.com/profile.php?id=100001004109730", "updated_time"=>"2010-05-04T21:53:29+0000", "first_name"=>"Jane", "email"=>"fb_janedoe@irrationaldesign.com"}
      @player.reload.first_name.should == "Jane"
      @player.reload.user.email.should == "fb_janedoe@irrationaldesign.com"
    end

    it "should handle player_id not matching player for user for facebook uid"

    it "should not overwrite email" do
      @player.user.update_attribute(:email, "custom@example.com")
      post :facebook, :fb_info => {"id"=>"100001004109730", "email"=>"fb_janedoe@irrationaldesign.com"}
      @player.reload.user.email.should == "custom@example.com"
    end

    it "should not break" do
      post :facebook
      response.should be_success
    end

    it "should not break if fb_auth error" do
      post :facebook, "fb_info"=> {"error"=> {"type"=>"OAuthException", "message"=>"Error validating access token."}}
      response.should be_success
    end
  end

  describe "update" do
    before :each do
      set_session_for_player(@player = Factory.create(:registered_player))
    end
    it "should create a profile" do
      put :update, {:preferred_profile => "profile", :player => {:profile_attributes => {:first_name => "johnny", :last_name => "doey"}}}

      @player.reload
      @player.profile.first_name.should == "johnny"
      @player.profile.last_name.should == "doey"
      @player.preferred_profile.should == @player.profile
    end

    it "should update the player and profile" do
      Factory.create(:profile, :first_name => "before", :player => @player)

      @player.gender.should == "m"
      @player.first_name.should == "before"

      put :update, {:preferred_profile => "profile", :player => {:gender => "f", :profile_attributes => {:id => @player.profile.id, :first_name => "after"}}}

      @player.reload
      @player.profile.first_name.should == "after"
      @player.gender.should == "f"


    end

    it "should set the preferred profile" do
      Factory.create(:facebook_profile, :fb_info => {"first_name" => "before"}.to_json, :player => @player)
      @player.preferred_profile.should == @player.facebook_profile

      put :update, {:preferred_profile => "profile", :player => {:gender => "f", :profile_attributes => {:first_name => "after"}}}

      @player.reload
      @player.preferred_profile.should == @player.profile
      @player.first_name.should == "after"
      @player.profile.first_name.should == "after"
    end

    describe "with interests" do
      it "should save the interests" do
        interests = [
          "Running",
          "Poodles",
          "Celtics",
          "Chicken",
          "Lasagna",
          "Dancing"
        ]
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
        }, :interests => interests.collect { |interest| {:title => interest} }

        @player.reload
        @player.interests.map(&:title).should =~ interests
      end
    end

  end
end
