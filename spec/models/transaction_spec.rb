require 'spec_helper'

describe Transaction do
  before :each do
    @user = Factory(:user)
  end

  it "should have initial state" do
    @user.credits.should == 0
    @user.should_not be_subscribed
    @user.subscribed_until.should be_blank
  end

  describe "credits" do
    it "should add credits" do
      @transaction = @user.transactions.create!(:amount => 22, :external_ref_id => "qwerty")

      @user.reload
      @user.credits.should == 22
      @user.should_not be_subscribed
    end

    it "should remove credits" do
      @user.update_attribute(:credits, 99)

      @transaction = @user.transactions.create!(:amount => -66, :external_ref_id => "qwerty")

      @user.reload
      @user.credits.should == 33
      @user.should_not be_subscribed
    end
  end

  describe "subscription" do
    it "should set subscribed_until" do
      @transaction = @user.transactions.create!(:subscribe => "success")

      @user.reload
      @user.credits.should == 0
      @user.should be_subscribed
      @user.subscribed_until.to_i.should be_close(1.month.from_now.to_i, 10)
    end

    it "should do nothing if subscribed_until is set" do
      @user.update_attribute(:subscribed_until,  until_date = 5.weeks.from_now)

      @transaction = @user.transactions.create!(:subscribe => "success")

      @user.reload
      @user.credits.should == 0
      @user.should be_subscribed
      @user.subscribed_until.should == until_date

    end
  end
end
