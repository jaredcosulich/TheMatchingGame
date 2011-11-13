require 'spec_helper'

describe "Registration" do
  describe "facebook" do
    it "should merge facebook and site info" do

      Photo.should_receive(:download_image).with("/assets/bug.jpg")

      get "/register/new"

      post "/account/profile/facebook", {:fb_info => {:id => "123456", :first_name => "First", :last_name => "Last"}}

      player = Player.find(session["player_id"])
      player.facebook_profile.first_name.should == "First"
      player.preferred_profile.should == player.facebook_profile
      player.user.email.should == "fb_123456@thematchinggame.com"

      post "/register", {:facebook_photo => "/assets/bug.jpg",
                         :player => {
                           :profile_attributes => {
                             :first_name => "firsty"},
                           :user_attributes => {
                             :email => "user@example.com",
                             :password => "password",
                             :password_confirmation => "password",
                             :terms_of_service => 1
                           }
                         }
      }


      player.reload.user.email.should == "user@example.com"
      player.profile.first_name.should == "firsty"
#      player.preferred_profile.should == player.profile
    end

  end

  describe "without facebook" do
    it "should create a player, user, and profile" do
      visit "/register/new"

      fill_in "email", :with => "another@example.com"
      fill_in "password", :with => "password"
      fill_in "password confirmation", :with => "password"
      fill_in "first name", :with => "firsty"
      choose "Male"
      attach_file "photo", "#{fixture_path}/cow.jpg"
      check "Terms"

      click_button "Save"

      current_url.should =~ /photos/

      player = Player.last
      player.user.email.should == "another@example.com"
      player.profile.first_name.should == "firsty"
      player.preferred_profile.should == player.profile
      player.facebook_profile.should be_nil

      current_url.should =~ /photos\/#{player.photos.first.id.to_obfuscated}/

      response.body.should include("Log Out")
      response.body.should_not include("Log In")


      submit_form "edit_photo_#{player.photos.first.id}"
      current_url.should =~ /photos\/#{player.photos.first.id.to_obfuscated}/
      response.body.should include("Log Out")
      response.body.should_not include("Log In")

    end
  end
end


