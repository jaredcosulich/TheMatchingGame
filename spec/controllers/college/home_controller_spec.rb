require 'spec_helper'

describe College::HomeController do

  describe "facebook validation" do
    it "should validate facebook and assign the registered user at the root college path" do
      FacebookProfile.should_receive(:get_access_token).and_return("FAKE_ACCESS_TOKEN")
      user = Factory(:college_photo).player.user
      FacebookProfile.should_receive(:find_or_create_college_user).and_return(user)
      get :index, :code => "AQCRsAmjkmv4qFzAm0fBNZ6pdA0OJEeFAljz5VcPJrW6yCeMcHMbZBUKMGjZwq7KRzTDxuAJVyPPhNPdwojM1Wxa1Jse8vi_or2igZPAb9PI-yocDI1tXnJGt3WVRa7eWJJ0OOaTLEfEZaUAcUvjotGz-GLB2MyGWAwA1txng3WXKUBojNUGGCYjxstn50u9NftTSaDR7avJcw4uglSkL4FJ"
      assigns(:current_player).should == user.player
    end
  end

end

