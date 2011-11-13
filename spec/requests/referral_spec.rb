require 'spec_helper'

describe "Referrals" do

  it "should create the player and referral on Game create" do
    referrer = Factory.create(:referrer, :uid => "xyz")

    get "/?r=xyz"
    Player.count.should == 0
    referrer.referrals.count.should == 0

    post "/games"
    Player.count.should == 1
    player = Player.last
    referrer.referrals.count.should == 1
    referrer.players.should == [player]

    post "/games"
    Player.count.should == 1
    referrer.referrals.count.should == 1
    referrer.players.should == [player]
  end

end
