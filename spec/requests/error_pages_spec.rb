require 'spec_helper'

describe "Error Pages" do
  it "should render not found" do
    get "/bad/path"
    response.code.should == "404"
#    response.body.should =~ /unable to find/
  end

  it "should redirect if user required but no user session" do
    get "/admin"

    response.should redirect_to(new_session_path)
  end

  it "should render not found on admin pages" do
    user = Factory.create(:user)
    post "/session", :user_session => {:email => user.email, :password => "password"}
    response.should redirect_to(account_path)

    get "/admin"
    response.code.should == "404"
    response.body.should =~ /unable to find/
  end

end
