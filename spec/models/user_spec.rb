require 'spec_helper'

def user_with_email(email)
  Factory.build(:user, :email => email, :password => "1234", :password_confirmation => "1234")
end

describe User do

  describe "email validations" do
    it "should require unique email" do
      user_with_email("User@example.com").save!

      duplicate = user_with_email("user@example.com")

      duplicate.should_not be_valid
      duplicate.errors_on(:email).should_not be_blank
    end
  end

  describe "find_or_create_fb" do
    it "should do nothing if fb_id is nil" do
      user = User.find_or_create_fb(nil, nil)
      user.should be_nil
    end

    it "should do nothing if fb_id is nil" do
      Factory.create(:user, :fb_id => nil)
      user = User.find_or_create_fb(nil, nil)
      user.should be_nil
    end

    it "should create a new player and fb user if player id is nil" do
      user = User.find_or_create_fb(nil, 12345)
      user.should_not be_new_record

      user.fb_id.should == 12345
      user.player.should == Player.last
      user.player.should be_anonymous
    end

    it "shoud look up player if player id nil but fb user exists" do
      fb_user = Factory.create(:user, :fb_id => 987)
      User.count.should == 1
      Player.count.should == 1

      user = User.find_or_create_fb(nil, 987)

      user.should == fb_user
      User.count.should == 1
      Player.count.should == 1
    end


    it "should lookup existing player and user" do
      player = Factory.create(:player)
      fb_user = Factory.create(:user, :fb_id => 987, :player => player)
      User.count.should == 1
      Player.count.should == 1

      user = User.find_or_create_fb(player.id, 987)

      user.should == fb_user
      user.player.should == player
      User.count.should == 1
      Player.count.should == 1
    end

    it "should create fb user for existing player" do
      player = Factory.create(:player)
      User.count.should == 0
      Player.count.should == 1

      user = User.find_or_create_fb(player.id, 456789)

      User.count.should == 1
      Player.count.should == 1

      user.player.should == player
      user.fb_id.should == 456789
    end

    it "should create fb user and new player if player id has other fb user" do
      player = Factory.create(:player)
      fb_user = Factory.create(:user, :fb_id => 987, :player => player)
      User.count.should == 1
      Player.count.should == 1

      user = User.find_or_create_fb(player.id, 123456789)
      User.count.should == 2
      Player.count.should == 2

      user.player.should_not == player
    end
  end

  describe "emailable" do
    it "should select users with real emails and the supplied preference" do
      user_with_both = Factory.create(:user)
      user_with_both.email_preference.update_attributes(:prediction_progress => true, :awaiting_response => true)
      user_with_prediction = Factory.create(:user)
      user_with_prediction.email_preference.update_attributes(:prediction_progress => true, :awaiting_response => false)
      user_with_response = Factory.create(:user)
      user_with_response.email_preference.update_attributes(:prediction_progress => false, :awaiting_response => true)
      facebook_user = Factory.create(:user, :email => "fb_123@thematchinggame.com")
      User.emailable('prediction_progress').should == [user_with_both, user_with_prediction]
      User.emailable('awaiting_response').should == [user_with_both, user_with_response]
    end
  end
end
