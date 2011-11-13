require 'spec_helper'

describe SessionsController do

  describe "create" do
    before(:each) do
      @password = "qw89udwdq"
      @email = "test@test.com"
      @user = Factory.create(:user, :email => @email, :password => @password, :password_confirmation => @password)
    end

    it "should redirect to account page if no post_login_path_set" do
      post :create, :user_session => {:email => @email, :password => @password}
      response.should redirect_to(account_path)

    end

    it "should redisplay if password wrong" do
      post :create, :user_session => {:email => @email, :password => "wrong"}
      response.should render_template(:new)
    end

  end


end
