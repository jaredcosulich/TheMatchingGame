require 'spec_helper'

describe "Auto Login Links" do
  before :each do
    user = Factory(:user)
    emailing = Emailing.create(:user => user)
    @auto_login_url = emailing.auto_login_path("/account/edit")
  end

  it "should log in as the user" do

    visit("/")
    response.body.should include("Log In")
    response.body.should_not include("Log Out")

    visit(@auto_login_url)

    current_url.should =~ /account\/edit/
    response.body.should include("Log Out")
    response.body.should_not include("Log In")

  end

  it "should not log in if token bad" do
    visit(@auto_login_url + "XXXX")

    current_url.should =~ /session\/new/
    response.body.should include("Log In")
    response.body.should_not include("Log Out")

  end
end
