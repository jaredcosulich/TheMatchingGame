require 'spec_helper'

describe LinksController do

  it "should decode link and redirect to link path" do
    get :index, :link => CGI::escape(photo_path(34)), :token => 'abc'
    response.should redirect_to photo_path(34)
  end

  it "should decode token and log in as that user" do
    user = Factory.create(:user)

    get :index, :link => CGI::escape("/path"), :token => user.perishable_token

    assigns[:current_player].should == user.player
  end

  it "should decode token and log in as that user, replacing existing player session" do
    set_session_for_player Factory.create(:player)
    user = Factory.create(:user)

    get :index, :link => CGI::escape("/path"), :token => user.perishable_token

    assigns[:current_player].should == user.player
  end

  it "should not login if bad token" do
    get :index, :link => CGI::escape("/path"), :token => "123"

    assigns[:current_player].should be_new_record
  end

  it "should not login, keeping existing player session, if bad token" do
    set_session_for_player(player = Factory.create(:player))
    get :index, :link => CGI::escape("/path"), :token => "123"

    assigns[:current_player].should == player
  end

  describe "link tracking" do
    it "should redirect to recorded paths" do
      emailing = Factory.create(:emailing)
      link = Factory.create(:link, :source => emailing, :path => "/path")

      get :index, :link => link.to_param, :token => 'abc'
      response.should redirect_to("/path")

      link.clicks.to_a.only.link.source.should == emailing
    end

    it "should redirect to account if it's confused" do
      get :index, :link => "999", :token => 'abc'

      response.should redirect_to("/account")
    end

  end
end
