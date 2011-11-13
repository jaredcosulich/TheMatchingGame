require 'spec_helper'

describe "Player#preferred_profile" do

  it "should be blank initially" do
    player = Factory.create(:player)
    player.reload

    player.preferred_profile.should be_nil

    player.first_name.should be_blank
    player.last_name.should be_blank
    player.location_name.should be_blank
    player.age.should be_blank
    player.sexual_orientation.should be_blank
  end

  it "should be the MG profile if it's the only one" do
    player = Factory.create(:player)
    player.create_profile(:first_name => "First", :location_name => "Here")
    player.reload

    player.preferred_profile.should == player.profile

    player.first_name.should == "First"
    player.location_name.should == "Here"

  end

  it "should be the FB profile if it's the only one" do
    player = Factory.create(:player)
    birthday = 38.years.ago.strftime("%m/%d/%Y")
    player.create_facebook_profile(:fb_info => {"first_name" => "Adam", "last_name" => "Abrons", "birthday" => birthday}.to_json)
    player.reload

    player.preferred_profile.should == player.facebook_profile

    player.first_name.should == "Adam"
    player.last_name.should == "Abrons"

    player.age.should == 38
  end
end
