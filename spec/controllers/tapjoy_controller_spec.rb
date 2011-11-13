require 'spec_helper'

describe TapjoyController do

  describe "#complete" do
    before :each do
      @user = Factory(:user, :id => 1)
      @verifier = "84976279ae0b537b252ec5817eb73940"
      @currency = 10
      @id = 1301967388
      @params = {"snuid" => 1, "id" => @id, "currency" => @currency, "verifier" => @verifier, "controller" => "tapjoy", "action" => "complete"}
    end

    it "should create a tapjoy_offer and assign credit" do
      @user.reload.credits.should == 0

      get :complete, @params
      response.should be_success

      @user.reload.credits.should == 10

      TapjoyOffer.count.should == 1
    end

    it "should verify signature" do
      TapjoyOffer.should_receive(:signature_valid?).with(@params.merge("verifier" => "bad_sig"), "bad_sig").and_return(false)

      get :complete, @params.merge(:verifier => "bad_sig")

      response.should be_forbidden

      TapjoyOffer.count.should == 0
    end
  end

end


__END__

/tapjoy?snuid=1&currency=10&id=1301967388&verifier=84976279ae0b537b252ec5817eb73940
