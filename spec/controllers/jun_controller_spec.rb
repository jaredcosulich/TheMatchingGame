require 'spec_helper'

describe JunController do

  describe "#complete" do
    before :each do
      @user = Factory(:user, :id => 1)
      @params = {"uid" => @user.id, "controller" => "jun", "action" => "complete"}
    end

    it "should create a tapjoy_offer and assign credit" do
      @user.reload.credits.should == 0

      get :complete, @params
      response.should be_success

      @user.reload.credits.should == 1

      JunOffer.count.should == 1
    end
  end
end

