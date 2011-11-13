require 'spec_helper'

describe "Logging In" do
  before :each do
    @password = "12345"
    @email = "test@test.com"
    @user = Factory.create(:user, :email => @email, :password => @password, :password_confirmation => @password)
  end

  it "should set the player_id on the session" do

    visit "/"

    click_link "Log In"

    fill_in "email", :with => @email
    fill_in "password", :with => @password
    
    click_button "Login"

    current_url.should =~ /leaderboard/

    session["player_id"].should == @user.player.id
  end

  it "should work for players with two users" do
    User.create!(:player_id => @user.player_id, :email => "another@example.com", :password => @password, :password_confirmation => @password, :terms_of_service => "1")

    visit "/"
    click_link "Log In"

    fill_in "email", :with => "another@example.com"
    fill_in "password", :with => @password
    click_button "Login"

    current_url.should =~ /leaderboard/
    response.body.should include("Log Out")
  end


  it "should redirect to the post-login path" do
    photo = Factory(:photo, :player => @user.player)

    visit photo_path(photo)

    current_url.should =~ /session\/new/

    fill_in "email", :with => @email
    fill_in "password", :with => @password

    click_button "Login"

    current_url.should include(photo_path(photo))

  end
end

