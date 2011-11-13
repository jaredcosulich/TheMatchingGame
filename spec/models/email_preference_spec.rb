require 'spec_helper'

describe EmailPreference do

  it "should be created when a user is created" do
    player = Factory.create(:player)
    player.create_user(:email => "e@example.com", :password => "123456", :password_confirmation => "123456", :terms_of_service => true)

    player.user.email_preference.should_not be_nil
    player.user.email_preference.awaiting_response.should be_true
    player.user.email_preference.prediction_progress.should be_true
  end
end
