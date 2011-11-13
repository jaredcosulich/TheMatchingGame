require 'spec_helper'

describe SocialGoldTransaction do
  before :each do
    @timestamp = "1275430704"
    @sample_params = {"pegged_currency_amount_iso_currency_code"=>"USD", "premium_currency_amount"=>"100", "simulated"=>"true", "timestamp"=>"1290107998", "socialgold_transaction_id"=>"2ae9a941244663b9c4d43a45b04a31b5", "amount"=>"100", "socialgold_transaction_status"=>"SUCCESS", "pegged_currency_amount"=>"200", "user_id"=>"1", "version"=>"1", "pegged_currency_label"=>"USD", "billing_country_code"=>"US", "cc_token"=>"f07yqm3x6w1o4wzwo47zck8ej01dp7n", "net_payout_amount"=>"180", "billing_zip"=>"98121", "premium_currency_label"=>"Credits", "offer_amount"=>"200", "external_ref_id"=>"", "event_type"=>"BOUGHT_CURRENCY", "offer_amount_iso_currency_code"=>"USD", "user_balance"=>"117500", "offer_id"=>"kyog2k1ctd4kmc0yeer8a5y22"}
    @valid_signature = "80ab3486125bedbaf1b9f10e1fc81c1d"
  end

  describe "initialize" do
    
    it "should save extra params in extra_fields" do
      user = Factory.create(:user)
      Factory.create(:transaction, :user => user, :source => user, :amount => 10)
      user.reload.credits.should == 10

      social_gold = SocialGoldTransaction.create!(@sample_params.merge("signature" => @valid_signature))
      social_gold.reload
      social_gold.amount.should == 100
      social_gold.offer_id.should == "kyog2k1ctd4kmc0yeer8a5y22"
      social_gold.extra_fields.should ==  {"simulated"=>"true", "cc_token"=>"f07yqm3x6w1o4wzwo47zck8ej01dp7n", "billing_country_code"=>"US", "billing_zip"=>"98121"}

      user.reload.credits.should == 10
    end

    it 'should create if signature valid' do
      SocialGoldTransaction.create!(@sample_params.merge("signature" => @valid_signature))
    end


    it "should raise if signature invalid" do
      lambda {
        SocialGoldTransaction.create!(@sample_params.merge("signature" => @valid_signature + "XXXX"))
      }.should raise_error(SocialGoldTransaction::InvalidSignature)
    end

    it "should find the associated transaction by external_ref_id and set the source to self"
    it "should do ??? if no associated transaction found"
  end

  describe "verify_signature" do

    it "should succeed if signature correct" do
      params = {"amount"=>"100", "external_ref_id"=>"a8674299c20838c98949afb7eb00bdd8", "ts"=>"1276800390"}

      SocialGoldTransaction.verify_signature("1813ec65eb17a866ec464966aa9ebc68", params)
    end
    it "should raise if signature incorrect" do
      params = {"amount"=>"100", "external_ref_id"=>"a8674299c20838c98949afb7eb00bdd8", "ts"=>"1276800390"}

      lambda {SocialGoldTransaction.verify_signature("1813ec65eb17a866ec464966aa9ebc68-BAD", params)}.should raise_error(SocialGoldTransaction::InvalidSignature)

    end

  end
end

__END__

ssh -R 8888:localhost:3000 jared@sandbox.abrons.com

timestamp = 1234567890
secret_key = "abcdefghijklmnopqrstuvwx"
string_before_signing = "timestamp1234567890abcdefghijklmnopqrstuvwx"
signature = md5(string_before_signing)

Our secret key: jyfurockyr1gb4ibsf1bod5ly
Our Merchant ID: 34796


http://www.thematchinggame.com/credits?signature=1d36d79382c29052ccc982b689228a81&timestamp=1275430704

pegged_currency_amount_iso_currency_code = USD
premium_currency_amount = 2500
offer_id = ir3p50llk7v8j0vscooh0dxpt
socialgold_transaction_id = 3fc414671980250905a56d441d2884bf
simulated = true
pegged_currency_amount = 2000
offer_amount = 2000
socialgold_transaction_status = SUCCESS
amount = 2500
pegged_currency_label = USD
version = 1
premium_currency_label = Credits
offer_amount_iso_currency_code = USD
user_id = 1234
user_balance = 2500
net_payout_amount = 1800
event_type = BOUGHT_CURRENCY
external_ref_id = f998obqjavkkyvlnkinwxzdwx
