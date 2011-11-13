require 'spec_helper'

describe "Priority" do

  describe "#create" do
    before :each do
      @photo = Factory(:registered_photo)
      @photo.player.user.update_attributes(:credits => 60)
    end

    it "should create a new priority and set the days_purchased based on the credits applied" do
      priority = Priority.create(:photo_id => @photo.id, :credits_applied => 30)
      priority.days_purchased.should == 15
      @photo.reload.priority_until.should be >= 14.days.from_now
    end

    it "should add on priority time if the photo is already a priority" do
      @photo.update_attributes(:priority_until => 3.days.from_now)
      priority = Priority.create(:photo_id => @photo.id, :credits_applied => 50)
      priority.days_purchased.should == 25
      @photo.reload.priority_until.should be >= 27.days.from_now
    end

    it "should add on priority time if the photo was a priority" do
      @photo.update_attributes(:priority_until => 10.days.ago)
      priority = Priority.create(:photo_id => @photo.id, :credits_applied => 10)
      priority.days_purchased.should == 5
      @photo.reload.priority_until.should be >= 5.days.from_now
    end

    it "should set the user on the priority" do
      priority = Priority.create(:photo_id => @photo.id, :credits_applied => 50)
      priority.user.should_not be_nil
      priority.user.should == @photo.player.user
    end


    it "should not save if the user does not have enough credits" do
      @photo.player.user.update_attributes(:credits => 20)
      priority = Priority.create(:photo_id => @photo.id, :credits_applied => 50)
      priority.should be_new_record
    end
  end
end
