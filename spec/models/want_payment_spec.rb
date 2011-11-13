require 'spec_helper'

describe WantPayment do
  before :each do
    @user = Factory(:user, :last_payment => nil)
  end

  describe "saving" do
    context "no amount specified" do
      before :each do
        Stripe::Charge.should_not_receive(:create)
        @payment = @user.want_payments.create!
      end

      it "should not try to make a payment if the amount is nil" do
        @payment.reload.charge_id.should be_blank
      end

      it "should not update the user's last payment date if the amount is nil" do
        @user.reload.last_payment.should be_nil
      end
    end

    context "amount specfied" do
      before :each do
        Stripe::Customer.should_receive(:create).and_return(Stripe::Charge.new("CUSTOMER_ID"))
        Stripe::Charge.should_receive(:create).and_return(Stripe::Charge.new("CHARGE_ID"))
        @payment = @user.want_payments.create!(:amount_dollars => 10, :amount_cents => 35, :card_info => {:email => @user.email})
      end

      it "should save the customer_id and charge_id" do
        @payment.reload
        @payment.amount.should == 1035
        @payment.customer_id.should == "CUSTOMER_ID"
        @payment.charge_id.should == "CHARGE_ID"
      end

      it "should update the user" do
        @user.reload.last_payment.should_not be_nil
      end

      it "should email a receipt"
    end

    context "no card info" do
      before :each do
        Stripe::Customer.should_not_receive(:create)
        Stripe::Charge.should_not_receive(:create)
        @payment = @user.want_payments.create(:amount_dollars => 10, :amount_cents => 35)
      end

      it "should save the customer_id and charge_id" do
        @payment.id.should be_nil
        @payment.amount.should == 1035
        @payment.customer_id.should be_nil
        @payment.charge_id.should be_nil
      end

      it "should update the user" do
        @user.reload.last_payment.should be_nil
      end
    end

    context "previous payments made" do
      it "should not create a new customer if the user already has a customer account" do
        Stripe::Customer.should_receive(:create).once.and_return(Stripe::Charge.new("CUSTOMER_ID"))
        Stripe::Charge.should_receive(:create).twice.and_return(Stripe::Charge.new("CHARGE_ID"))
        @user.want_payments.create!(:amount_dollars => 10, :amount_cents => 35, :card_info => {:email => @user.email})
        @user.want_payments.create!(:amount_dollars => 10, :amount_cents => 35, :card_info => {:email => @user.email})
      end
    end
  end
end

