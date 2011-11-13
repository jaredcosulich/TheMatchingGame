require 'spec_helper'

describe PasswordResetsController do
  before(:each) do
    @email = "example@example.com"
    @user = Factory.create(:user, :email => @email)
  end

  describe "create" do
    it "should not set a perishable token if the email is not associated with a user" do
      post :create, :password_reset => {:email => 'wrong_email@example.com'}
      response.should redirect_to(new_password_reset_path)
      @user.perishable_token.should_not be_nil
    end

    it "should set the user with a new perishable token" do
      post :create, :password_reset => {:email => @email}
      response.should redirect_to(new_session_path)
      @user.perishable_token.should_not be_nil
    end
  end

  describe "edit" do
    render_views
    it "should set token in a hidden field if the token provided is correct" do
      @user.reset_perishable_token!
      get :edit, :token => @user.perishable_token
      response.should be_success
      assert_select("input[name=?][type=?]", "token", "hidden")
    end

    it "should redirect to password reset page if token is not found" do
      @user.reset_perishable_token!
      get :edit, :token => 'bad_token'
      response.should redirect_to(new_password_reset_path)
    end
  end


  describe "update" do
    it "should reset the password only if token provided equals user's token and password = password_confirmation" do
      @user.reset_perishable_token!
      old_crypted_password = @user.crypted_password
      put :update, :token => @user.perishable_token, :password_reset => {:password => "anewpassword", :password_confirmation => "anewpassword"}
      response.should redirect_to(account_path)
      assigns[:current_player].should == @user.player
      @user.reload.crypted_password.should_not == old_crypted_password
    end

    it "should not reset the password if the password != password_confirmation" do
      @user.reset_perishable_token!
      old_crypted_password = @user.crypted_password
      put :update, :token => @user.perishable_token, :password_reset => {:password => "onepassword", :password_confirmation => "differentpassword"}
      response.should be_success
      assigns[:current_player].should_not == @user.player
      @user.reload.crypted_password.should == old_crypted_password
    end

    it "should not reset the password and redirect to password reset page if token is not found" do
      @user.reset_perishable_token!
      old_crypted_password = @user.crypted_password
      put :update, :token => "bad_token", :password_reset => {:password => "anewpassword", :password_confirmation => "anewpassword"}
      response.should redirect_to(new_password_reset_path)
      assigns[:current_player].should_not == @user.player
      @user.reload.crypted_password.should == old_crypted_password
    end
  end
end
