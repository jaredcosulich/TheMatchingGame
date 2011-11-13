require 'spec_helper'

describe WantPaymentsController do

  before :each do
    set_session_for_player @player = Factory.create(:registered_player)
    @user = @player.user
  end

  describe "#index" do
    it "should create a new want_payment if there isn't a blank one waiting" do
      WantPayment.count.should == 0
      get :index
      want_payment = WantPayment.all.only
      want_payment.amount.should be_nil
      want_payment.charity_name.should be_nil
      want_payment.user.should == @user
    end

    it "should use the existing want_payment if there is a blank one waiting" do
      WantPayment.count.should == 0
      want_payment = WantPayment.create!(:user => @user)
      WantPayment.count.should == 1
      get :index
      WantPayment.all.only.should == want_payment
      want_payment.reload
      want_payment.amount.should be_nil
      want_payment.charity_name.should be_nil
      want_payment.user.should == @user
    end

    it "should create a new want_payment if there are older ones that are filled in" do
      WantPayment.count.should == 0
      Stripe::Customer.should_receive(:create).and_return(Stripe::Charge.new("CUSTOMER_ID"))
      Stripe::Charge.should_receive(:create).and_return(Stripe::Charge.new("CHARGE_ID"))
      @user.want_payments.create!(:amount_dollars => 10, :amount_cents => 35, :card_info => {:email => @user.email})
      WantPayment.count.should == 1

      get :index
      WantPayment.count.should == 2
      want_payment = WantPayment.last
      want_payment.amount.should be_nil
      want_payment.charity_name.should be_nil
      want_payment.user.should == @user
    end
  end

  describe "#update" do
    it "should work" do
      Stripe::Customer.should_receive(:create).and_return(Stripe::Charge.new("CUSTOMER_ID"))
      Stripe::Charge.should_receive(:create).and_return(Stripe::Charge.new("CHARGE_ID"))

      want_payment = @user.want_payments.create!
      put :update, :id => want_payment.id,
        "name"=>"Jared Cosulich",
        "commit"=>"Save and Continue Using The Site",
        "want_payment"=>{
          "percent_to_charity"=>"30",
          "amount_cents"=>"00",
          "amount_dollars"=>"6",
          "charity_website"=>"http://www.khanacademy.org/",
          "charity_name"=>"Khan Academy"
        },
        "authenticity_token"=>"GWRRksdXIdBGxBBOfxl+CGNuVzQ1/A4OWKrJdvPe7rY=",
        "utf8"=>"✓",
        "id"=>"2",
        "stripeToken"=>"asduihi3rh",
        "email"=>"jared.cosulich@gmail.com"

      want_payment.reload
      want_payment.customer_id.should_not be_nil
      want_payment.charge_id.should_not be_nil
    end
  end
end
