require 'spec_helper'

describe ConnectionsController do
  before :each do
    @combo    = Factory.create(:combo)
    @user_one = Factory.create(:user, :player => @combo.photo_one.player)
    @user_two = Factory.create(:user, :player => @combo.photo_two.player)
  end

  describe "access control" do

    it "should be viewable by the user one in the combo" do
      login_as @user_one

      get :show, :id => @combo.to_param

      response.should be_success
      assigns[:combo].should == @combo
    end

    it "should be viewable by the user two in the combo" do
      login_as @user_two
      get :show, :id => @combo.to_param
      response.should be_success
    end

    it "should not be viewable by another user" do
      login_as Factory.create(:user)
      get :show, :id => @combo.to_param
      response.code.should == "403"
    end

    it "should not be viewable by anonymous" do
      get :show, :id => @combo.to_param
      response.should redirect_to(new_session_path)
    end

    it "should not be viewable by anonymous player" do
      set_session_for_player Factory.create(:player)
      get :show, :id => @combo.to_param
      response.should redirect_to(new_session_path)
    end

  end

  describe "show" do
    describe "no connection" do

      it "should show render successfully" do
        login_as @user_one
        get :show, :id => @combo.to_param

        response.should be_success
        assigns[:messages].should be_nil
      end

    end

    describe "messages" do
      render_views

      describe "normal back and forth" do
        before :each do
          @user_one.transactions.create(:amount => 100, :source => @user_one)
          @connect_one = @combo.connect(@combo.photo_one, "hi, two")
          @message_two = @combo.message(@combo.photo_two, "hello, one")
        end

        it "should load messages in order" do
          login_as @user_one
          get :show, :id => @combo.to_param

          combo_actions = assigns[:combo_actions]
          combo_actions.should == [@connect_one, @message_two]
          @combo.combo_actions.length.should == 2
        end

        it "should mark the messages as read" do
          login_as @user_one

          @message_two.should be_unread(@user_one.player)
          @message_two.should_not be_unread(@user_two.player)

          get :show, :id => @combo.to_param

          @message_two.reload
          @message_two.should_not be_unread(@user_one.player)
          @message_two.should_not be_unread(@user_two.player)

          response.body.should =~ /connections\/#{@combo.id}\/action/
        end
      end

      describe "one sided conversation" do
        it "should not show the form if two messages have already been sent" do
          @user_one.transactions.create(:amount => 100, :source => @user_one)
          @connect_one = @combo.connect(@combo.photo_one, "hi, two")
          @another_message = @combo.message(@combo.photo_one, "hello, is anyone there?")

          login_as @user_one
          get :show, :id => @combo.id

          response.body.should_not =~ /connections\/#{@combo.id}\/action/
        end
      end
    end

  end

  describe "cancel" do
    it "should cancel the connection and refund the credits if the other photo has not accepted"
    it "should fail if the other photo has accepted"
  end

  describe "action" do
    before :each do
      login_as @user_one
    end

    it "should create a 'connect' action and debits account if not connected yet" do
      @user_one.transactions.create(:amount => 50, :source => @user_one)
      post :action, :id => @combo.to_param, :combo_action => {:action => 'connect'}
      response.should redirect_to(connection_path(@combo))
      connection = @combo.combo_actions.only
      connection.action.should == 'connect'
      connection.photo.should == @combo.photo_one
#      @user_one.reload.credits.should == 30
    end

    xit "should not create a 'connect' action if user does not have enough credits" do
      @user_one.credits.should == 0
      post :action, :id => @combo.to_param, :combo_action => {:action => 'connect'}
      @combo.combo_actions.length.should == 0
      @user_one.reload.credits.should == 0
      flash[:notice].should =~ /enough credits/
      response.should redirect_to(connection_path(@combo))
    end

    describe "message creation" do
      before(:each) do
        @user_two.transactions.create(:amount => 100, :source => @user_two)
        @combo.connect(@combo.photo_two, "hi")
        post :action, :id => @combo.to_param, :combo_action => {:action => 'message', :message => "Hey there!"}
      end

      it "should create new messages in the thread" do
        message = @combo.reload.messages.to_a.only
        message.message.should == "Hey there!"
        message.actor.should == @user_one.player
      end

    end

  end

  describe "block/ignore" do
    it "should allow one user to ignore the other"
  end

  describe "connect" do
    before :each do
      @combo = Factory.create(:combo, :photo_one => Factory.create(:registered_photo, :gender => "m"), :photo_two => Factory.create(:registered_photo, :gender => "f"))
      @combo.create_response(:photo_one_answer => "good")
      @user  = @combo.photo_one.player.user
      @user.update_attribute(:credits, 85)
      login_as @user
    end

    it "should set an interested response" do
      post :connect, :id => @combo.id, :combo_action => {:message => "Hello there."}
      @combo.response.reload.photo_one_answer.should == "interested"
    end

    it "should create ComboActions to connect and message" do

      @combo.combo_actions.count.should == 0

      post :connect, :id => @combo.id, :combo_action => {:message => "Hello there."}

      response.should redirect_to connection_path(@combo)

#      @user.reload.credits.should == 65
      @combo.reload.should be_connected

      connect = @combo.combo_actions.only
      connect.message.should == "Hello there."
      connect.action.should == "connect"
    end

    it "should send 1 email" do
      ActionMailer::Base.deliveries.clear
      Delayed::Job.delete_all

      post :connect, :id => @combo.id, :combo_action => {:message => "Hello there."}

      Delayed::Job.all.map { |j| j.invoke_job }


      ActionMailer::Base.deliveries.length.should == 1
    end

  end

  describe "unlock" do
    before :each do
      @combo   = Factory(:combo, :photo_one => Factory(:registered_photo))
      @player = set_session_for_player(@combo.photo_one.player)
    end

    it "should unlock for the player" do
      get :unlock, :id => @combo.to_param, :amount => "200", :external_ref_id => "3c22779992fe737e5f27731c11330c3e", :sig => "45735ac10847b212b4f95f442013d3c6", :ts => "1290025486"

      response.should be_success
      response.should render_template("credits/complete")

      @combo.response.should be_photo_one_unlocked
      @combo.response.should_not be_photo_two_unlocked
    end

    it "should unlock for the player when response exists" do
      @combo.create_response(:photo_one_answer => "good", :photo_two_answer => "good")
      get :unlock, :id => @combo.to_param, :amount => "200", :external_ref_id => "3c22779992fe737e5f27731c11330c3e", :sig => "45735ac10847b212b4f95f442013d3c6", :ts => "1290025486"

      response.should be_success
      response.should render_template("credits/complete")

      @combo.response.reload
      @combo.response.should be_photo_one_unlocked
      @combo.response.should_not be_photo_two_unlocked
    end


    it "should not unlock if the signature is incorrect" do
      get :unlock, :id => @combo.to_param, :amount => "200", :external_ref_id => "3c22779992fe737e5f27731c11330c3e", :sig => "XXXXX", :ts => "1290025486"

      response.should be_success
      response.should render_template("credits/complete")

      @combo.response.should be_nil
    end

  end
end
