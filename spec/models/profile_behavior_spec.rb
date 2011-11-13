require 'spec_helper'

describe "ProfileBehavior" do

  describe "age" do
    it "should calculate from birthdate" do
      profile = Factory.create(:profile, :birthdate => 33.years.ago.to_date)

      profile.age.should == 33
    end

    it "should be nil if no birthdate" do
      profile = Factory.create(:profile, :birthdate => nil)

      profile.age.should be_nil
    end
  end
end
