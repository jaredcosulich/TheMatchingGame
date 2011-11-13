require 'spec_helper'

describe ComboAction do
  before :each do
    @combo = Factory.create(:response, :photo_one_answer => :good).combo
    @user_one = @combo.photo_one.player.user
    @user_two = @combo.photo_two.player.user
    Factory.create(:initial_credits, :user => @user_one)
    Factory.create(:initial_credits, :user => @user_two)
    ActionMailer::Base.deliveries.clear
  end

  describe "actor?" do
    before :each do
      @action = @combo.connect(@combo.photo_one, "hi")

    end
    it "should be true for the creator" do
      @action.should be_actor(@combo.photo_one.player)
    end
    it "should be false for other players" do
      @action.should_not be_actor(@combo.photo_two.player)
      @action.should_not be_actor(Factory.create(:player))
    end
  end

  describe "connection notifications" do
    before :each do
      @combo.connect(@combo.photo_one, "hi")
    end


    xit "should reduce the user's credits when a 'connect' action is created" do
      @user_one.reload.credits.should == 80
    end

    it "should send an email when one person wants to connect" do
      Delayed::Job.last.invoke_job

      connection_notification = ActionMailer::Base.deliveries.only
      connection_notification.to_addrs.first.to_s.should include(@user_two.email)
      connection_notification.body.should =~ /You have a new message/
    end

    it "should not be notified if canceled" do
      Delayed::Job.delete_all
      @combo.cancel(@combo.photo_one)
      Delayed::Job.count.should == 0
    end

  end

  describe "#connection_action" do
    it "should be not_connected when no one has connected" do
      @combo.connection_action.should == "connect"
    end

    describe "one connect" do
      before :each do
        @combo.connect(@combo.photo_one, "hi")
      end

      it "should be message for both players" do
        @combo.connection_action.should == "message"
      end

      describe "cancellation" do
        before :each do
          @combo.cancel(@combo.photo_one)
        end
        
        it "should be not_connected for both players" do
          @combo.connection_action.should == "connect"
        end

        it "should reconnect as above" do
          @combo.connect(@combo.photo_one, "hi")
          @combo.connection_action.should == "message"

        end
      end
    end

  end

  describe "#unread_message_count" do
    it "should return the count of messages that have not yet been viewed" do
      ActiveRecord::Observer.with_observers(:combo_observer) do
        combo = Factory(:combo)
        second_combo = Factory(:combo, :photo_one => combo.photo_one)
        connect = combo.connect(combo.photo_two, "Hey there")
        connect_two = second_combo.connect(combo.photo_two, "Hey there 2")
        ComboAction.unread_message_count(combo.photo_one.player).should == 2
        connect_two.update_attribute(:viewed_at, Time.new.utc)
        ComboAction.unread_message_count(combo.photo_one.player).should == 1
      end
    end
  end

  pending "messaging" do
    before :each do
      @combo.connect(@combo.photo_one, "hello")
      Delayed::Job.delete_all
      @combo.message(@combo.photo_two, "hello back")
    end

    it "should track read state of the message" do
      messages = @combo.messages.to_a

      message = messages.only
      message.should be_unread(@combo.photo_one.player)
      message.should_not be_unread(@combo.photo_two.player)

      message.update_attribute(:viewed_at, Time.now)
      message.should_not be_unread(@combo.photo_one.player)
      message.should_not be_unread(@combo.photo_two.player)

    end

    it "should email the other user when a message is created" do
      Delayed::Job.last.invoke_job

      notification = ActionMailer::Base.deliveries.only

      notification.to_addrs.first.to_s.should include(@user_one.email)
      notification.body.should =~ /message/
    end

    it "should reject messages if combo not connected" do
      combo = Factory.create(:response, :photo_one_answer => :good).combo
      combo.message(combo.photo_one, "reject this").should_not be_valid
      combo.combo_actions.count.should == 0
    end
  end

  pending "credits and debits" do
    it "should debit on connect" do
      @user_one.credits.should == 100
      @user_two.credits.should == 100
      @combo.connect(@combo.photo_one, "hi")
      @user_one.reload.credits.should == 80
      @user_two.credits.should == 100
    end

    it "should credit on cancel" do
      @user_one.credits.should == 100
      @user_two.credits.should == 100
      @combo.connect(@combo.photo_one, "hi")
      @user_one.reload.credits.should == 80

      @combo.cancel(@combo.photo_one)
      @user_one.reload.credits.should == 100
      @user_two.reload.credits.should == 100

      @combo.reload.should_not be_connected

      @combo.connect(@combo.photo_two, "now hi")
      @user_one.reload.credits.should == 100
      @user_two.reload.credits.should == 80
      @combo.reload.should be_connected
    end

    it "should reject cancel if there are messages" do
      @user_one.credits.should == 100

      @combo.connect(@combo.photo_one, "message")
      @user_one.reload.credits.should == 80

      @combo.message(@combo.photo_two, "reply")
      @combo.reload.should be_reciprocated
      @user_one.reload.credits.should == 80


      @combo.cancel(@combo.photo_one).should_not be_valid
      @user_one.reload.credits.should == 80
      @combo.reload.should be_reciprocated
    end
  end
end
