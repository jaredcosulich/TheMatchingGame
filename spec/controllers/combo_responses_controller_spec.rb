require 'spec_helper'

describe ComboResponsesController do

  describe "create" do
    before(:each) do
      @combo = Factory.create(:combo, :photo_one => Factory.create(:registered_photo, :gender => "m"), :photo_two => Factory.create(:registered_photo, :gender => "f"))
    end

    it "should accept a question and a response and create a new response for the combo, assigning the answer to the correct photo" do
      login_as @combo.photo_one.player.user

      post :create, {:combo_id => @combo.id, :response => "good"}

      @combo.reload.response.should_not be_nil

      @combo.response.photo_one_answer.should == "good"
      @combo.response.photo_two_answer.should be_nil
    end

    it "should update a response, assigning the answer to the correct photo if a response already exists" do
      response = Factory.create(:response, :combo => @combo, :photo_one_answer => 'good', :photo_two_answer => 'good')
      login_as @combo.photo_two.player.user

      post :create, {:combo_id => @combo.id, :response => "interested"}

      @combo.reload.response.should == response

      @combo.response.photo_one_answer.should == "good"
      @combo.response.photo_two_answer.should == "interested"
    end

    it "should update rating if sent" do
      login_as @combo.photo_one.player.user

      post :create, {:combo_id => @combo.id, :response => "good rating_8"}

      @combo.reload.response.should_not be_nil

      @combo.response.photo_one_answer.should == "good"
      @combo.response.photo_one_rating.should == 8
      @combo.response.photo_two_answer.should be_nil

    end

    it "should update a response, even if blank, assigning the answer to the correct photo if a response already exists" do
      response = Factory.create(:response, :combo => @combo, :photo_one_answer => 'good', :photo_two_answer => 'good')
      login_as @combo.photo_two.player.user

      post :create, {:combo_id => @combo.id, :response => ""}

      @combo.reload.response.should == response

      @combo.response.reload.photo_one_answer.should == "good"
      @combo.response.reload.photo_two_answer.should be_nil
    end

    it "should reject if user is not the owner of either photo" do
      login_as Factory.create(:user)

      post :create, {:combo_id => @combo.id, :response => "good"}

      response.code.should == "403"
    end
  end

end
