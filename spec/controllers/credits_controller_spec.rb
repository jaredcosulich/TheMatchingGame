require 'spec_helper'

describe CreditsController do
  before :each do
    @user = Factory.create(:user)
  end

  it "should create a new credit history when a postback is received and update the user's credits (another example)" do
    HoptoadNotifier.should_not_receive(:notify)
    params = {"pegged_currency_amount_iso_currency_code"=>"USD", "premium_currency_amount"=>"100", "simulated"=>"true", "timestamp"=>"1290107998", "socialgold_transaction_id"=>"2ae9a941244663b9c4d43a45b04a31b5", "amount"=>"100", "signature"=>"80ab3486125bedbaf1b9f10e1fc81c1d", "socialgold_transaction_status"=>"SUCCESS", "pegged_currency_amount"=>"200", "user_id"=>"1", "version"=>"1", "pegged_currency_label"=>"USD", "billing_country_code"=>"US", "cc_token"=>"f07yqm3x6w1o4wzwo47zck8ej01dp7n", "net_payout_amount"=>"180", "billing_zip"=>"98121", "premium_currency_label"=>"Credits", "offer_amount"=>"200", "external_ref_id"=>"", "event_type"=>"BOUGHT_CURRENCY", "offer_amount_iso_currency_code"=>"USD", "user_balance"=>"117500", "offer_id"=>"kyog2k1ctd4kmc0yeer8a5y22"}
    post :create, params
    response.should be_success

    social_gold_transaction = SocialGoldTransaction.all.only
    social_gold_transaction.user_id.should == 1
  end

  it "should create a new credit history when a postback is received and update the user's credits (from production)" do
    HoptoadNotifier.should_not_receive(:notify)

    params = {"pegged_currency_amount_iso_currency_code"=>"USD", "premium_currency_amount"=>"100", "timestamp"=>"1290106434", "socialgold_transaction_id"=>"c1323ca6d1dca3e29be381ae0d11810a", "amount"=>"100", "signature"=>"b3853f8c05d3274a73f048b9fec3ef62", "socialgold_transaction_status"=>"SUCCESS", "pegged_currency_amount"=>"200", "user_id"=>"93", "version"=>"1", "pegged_currency_label"=>"USD", "billing_country_code"=>"US", "cc_token"=>"4eold35f47d7p9w1nd3qhrl71ivdbes", "net_payout_amount"=>"180", "billing_zip"=>"94610", "premium_currency_label"=>"Credits", "offer_amount"=>"200", "external_ref_id"=>"", "event_type"=>"BOUGHT_CURRENCY", "offer_amount_iso_currency_code"=>"USD", "user_balance"=>"100", "offer_id"=>"bcny7v74rpn751ldr02ojc6p6"}
    post :create, params

    response.should be_success

    social_gold_transaction = SocialGoldTransaction.all.only
    social_gold_transaction.user_id.should == 93
  end

  it "should not work without a valid signature" do
    HoptoadNotifier.should_receive(:notify)
    post :create,
         :signature => "xxx6d79382c29052ccc982b689228xxx",
         :timestamp => "1275430704",
         :pegged_currency_amount_iso_currency_code => "USD",
         :premium_currency_amount => "2500",
         :offer_id => "ir3p50llk7v8j0vscooh0dxpt",
         :socialgold_transaction_id => "3fc414671980250905a56d441d2884bf",
         :simulated => "true",
         :pegged_currency_amount => "2000",
         :offer_amount => "2000",
         :socialgold_transaction_status => "SUCCESS",
         :amount => "2500",
         :pegged_currency_label => "USD",
         :version => "1",
         :premium_currency_label => "Credits",
         :offer_amount_iso_currency_code => "USD",
         :user_id => "#{@user.id}",
         :user_balance => "2500",
         :net_payout_amount => "1800",
         :event_type => "BOUGHT_CURRENCY",
         :external_ref_id => "f998obqjavkkyvlnkinwxzdwx"

    @user.reload.credits.should == 0

    response.should be_success
  end

  describe "complete" do
    before :each do
      login_as @user
      Factory.create(:initial_credits, :user => @user)
      @user.reload.credits.should == 100
    end

    describe "successful transaction" do
      before(:each) do
        mock_client = mock("currency_client")
        SocialGoldTransaction.should_receive(:currency_client).and_return(mock_client)
        body = <<-json
          {\"transactions\":[
            {\"timestamp\":\"1276801529\",\"premium_currency_amount\":\"7500\",\"socialgold_transaction_id\":\"79949806e04abbdce777238b646f05d1\",\"transaction_type\":\"BUY_CURRENCY\",\"socialgold_transaction_status\":\"SUCCESS\",\"description\":\"75 Credits\",\"app_params\":null,\"external_ref_id\":\"35b3e492b08fd50f200034ec798f323b\"},
            {\"timestamp\":\"1276801478\",\"premium_currency_amount\":\"2500\",\"socialgold_transaction_id\":\"611d63536ca27cf07a9b6e41f6594a01\",\"transaction_type\":\"BUY_CURRENCY\",\"socialgold_transaction_status\":\"SUCCESS\",\"description\":\"25 Credits\",\"app_params\":null,\"external_ref_id\":\"36f5660d35e61a51ffe242cebdfc77bf\"}
          ],\"query_parameters\":{\"end_ts\":\"\",\"start_ts\":1276799036,\"limit\":\"2\"}}
        json

        mock_client.should_receive(:get_transactions).and_return({:body => body})
      end

      it "should add credits if success" do

        get :complete,
            :sig => "df8324c5a6c559d35f44e5422ab77cf1",
            :ts => "1276793050",
            :amount => "2000",
            :external_ref_id => "36f5660d35e61a51ffe242cebdfc77bf"

        response.should be_success
        flash[:notice].should =~ /added/

        transaction = Transaction.last
        transaction.amount.should == 25
        transaction.external_ref_id.should == "36f5660d35e61a51ffe242cebdfc77bf"

        @user.reload.credits.should == 125
      end

      it "should not add credits if this refid has been processed already" do
        @user.transactions.create(:external_ref_id => "36f5660d35e61a51ffe242cebdfc77bf", :amount => 20)
        @user.reload.credits.should == 120

        @user.transactions.count.should == 2

        get :complete,
            :sig => "df8324c5a6c559d35f44e5422ab77cf1",
            :ts => "1276793050",
            :amount => "2000",
            :external_ref_id => "36f5660d35e61a51ffe242cebdfc77bf"

        response.should be_success
        flash[:notice].should be_blank

        @user.reload
        @user.transactions.count.should == 2
        @user.credits.should == 120
      end

    end

    it "should add credits if failure" do
      get :complete,
          :status => "failure",
          :sig => "1d36d79382c29052ccc982b689228a81",
          :ts => "1275430704",
          :amount => "2500",
          :external_ref_id => "f998obqjavkkyvlnkinwxzdwx"

      response.should be_success

      flash[:notice].should =~ /problem/
      @user.transactions.count.should == 1
      @user.reload.credits.should == 100
    end

    it "should not do anything if sig is bad" do
      get :complete,
          :sig => "1d36d79382c29052ccc982b689228a81bad",
          :ts => "1275430704",
          :amount => "2500",
          :external_ref_id => "f998obqjavkkyvlnkinwxzdwx"

      response.should be_success

      flash[:notice].should =~ /problem/
      @user.transactions.count.should == 1
      @user.reload.credits.should == 100
    end
  end

end

__END__
amount=2000&external_ref_id=36f5660d35e61a51ffe242cebdfc77bf&result=success&sig=df8324c5a6c559d35f44e5422ab77cf1&ts=1276793050
