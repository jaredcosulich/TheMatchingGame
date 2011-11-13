require 'spec_helper'

describe Response do

  describe "before_save" do
    it "should set any answer that is 'unanswered' to nil and nil rating" do
      response = Factory.create(:response, :photo_one_answer => 'good', :photo_one_rating => 6, :photo_two_answer => 'interested', :photo_two_rating => 9)
      response.update_attributes(:photo_one_answer => 'unanswered')
      response.reload.photo_one_answer.should be_nil
      response.reload.photo_one_rating.should be_nil
      response.reload.photo_two_answer.should == "interested"
      response.reload.photo_two_rating.should == 9
    end

  end

  describe "last_full_answer" do
    it "should look like 'He/She said yes/no'" do
      Factory.create(:response, :photo_one_answer => "good").last_full_answer.should == "He said yes"
      Factory.create(:response, :photo_two_answer => "bad").last_full_answer.should == "She said no"
      Factory.create(:response).last_full_answer.should be_blank
    end
  end

  describe "responded_at" do
    it "should be updated when the response is created or updated" do
      response = Factory.create(:response, :photo_one_answer => "good")

      response.photo_one_answered_at.should_not be_nil
      response.photo_two_answered_at.should be_nil

      response.update_attribute(:photo_two_answer, "interested")

      response.reload
      response.photo_one_answered_at.should_not be_nil
      response.photo_two_answered_at.should_not be_nil
      [response.photo_two_answered_at, response.photo_one_answered_at].max.should == response.photo_two_answered_at

    end
  end

  describe "verified" do
    it "should be verified_good only if both good or interested" do
      Factory.create(:response, :photo_one_answer => "good", :photo_two_answer => "interested").should be_verified_good
      Factory.create(:response, :photo_one_answer => "good", :photo_two_answer => "good").should be_verified_good

      Factory.create(:response).should_not be_verified_good
      Factory.create(:response, :photo_one_answer => "good").should_not be_verified_good
      Factory.create(:response, :photo_one_answer => "interested", :photo_two_answer => "bad").should_not be_verified_good
    end

    it "should be verified_bad if either answer is bad" do
      Factory.create(:response).should_not be_verified_bad
      Factory.create(:response, :photo_one_answer => "good", :photo_two_answer => "interested").should_not be_verified_bad
      Factory.create(:response, :photo_one_answer => "good", :photo_two_answer => "good").should_not be_verified_bad

      Factory.create(:response, :photo_one_answer => "bad").should be_verified_bad
      Factory.create(:response, :photo_one_answer => "interested", :photo_two_answer => "bad").should be_verified_bad
    end
  end

  describe "notification of other player" do
    before :each do
      @response = Factory.create(:response)
      @combo    = @response.combo
      @user_one = @combo.photo_one.player.user
      @user_two = @combo.photo_two.player.user
      Delayed::Job.delete_all
    end

    it "should email both players if both thought good match" do
      @response.update_attribute(:photo_one_answer, "good")
      Delayed::Job.count.should == 0

      @response.update_attribute(:photo_two_answer, "good")
      Delayed::Job.all.each { |j| j.invoke_job }

      ActionMailer::Base.deliveries.length.should == 2
      bodies   = ActionMailer::Base.deliveries.map(&:body)
      to_addrs = ActionMailer::Base.deliveries.map { |delivery| delivery.to_addrs.first.to_s }
      [@user_one.email, @user_two.email].each { |email| to_addrs.should include(email) }
      bodies.each { |body| body.should =~ /both thought you would be a good match for each other!/ }
    end

    it "should email the non-connected player if both thought good match" do
      @user_two.player.update_attribute(:connectable, false)
      @response.reload

      @response.update_attribute(:photo_one_answer, "good")
      Delayed::Job.count.should == 0

      @response.update_attribute(:photo_two_answer, "good")
      Delayed::Job.all.each { |j| j.invoke_job }

      message = ActionMailer::Base.deliveries.only
      message.to_addrs.first.to_s.should =~ /#{@user_two.email}/
      message.body.should =~ /Your status is currently set to/
    end

    it "should not email both players if one upgrades response from good to interested unless forced" do
      @response.update_attribute(:photo_one_answer, "good")
      Delayed::Job.count.should == 0

      @response.update_attribute(:photo_two_answer, "good")
      Delayed::Job.delete_all

      @response.update_attribute(:photo_two_answer, "interested")
      Delayed::Job.count.should == 0

      @response.notify_both_players_on_mutual_good(true)
      Delayed::Job.all.each { |j| j.invoke_job }

      ActionMailer::Base.deliveries.length.should == 2
      bodies   = ActionMailer::Base.deliveries.map(&:body)
      to_addrs = ActionMailer::Base.deliveries.map { |delivery| delivery.to_addrs.first.to_s }
      [@user_one.email, @user_two.email].each { |email| to_addrs.should include(email) }
      bodies.each { |body| body.should =~ /both thought you would be a good match for each other!/ }
    end

    it "should not email if the pair is a perfect pair challenge" do
      @response.combo.photo_one.update_attribute(:couple_combo_id, @response.combo.id)
      @response.combo.photo_two.update_attribute(:couple_combo_id, @response.combo.id)
      @response.update_attribute(:photo_one_answer, "good")
      Delayed::Job.count.should == 0

      @response.update_attribute(:photo_two_answer, "interested")
      Delayed::Job.count.should == 0
    end

    it "should not email if the other player has said 'bad match'" do
      @response.update_attribute(:photo_one_answer, "bad")
      Delayed::Job.count.should == 0

      @response.update_attribute(:photo_two_answer, "interested")

      Delayed::Job.count.should == 0
    end

    it "should not email if the other player is not connectable" do
      @user_two.player.update_attribute(:connectable, :false)

      Delayed::Job.count.should == 0

      @response.reload.update_attribute(:photo_one_answer, "interested")

      Delayed::Job.count.should == 0
    end

    it "should allow force send" do
      @response.notify_other_player(:photo_two)
      Delayed::Job.last.invoke_job
      verify_only_delivery(@user_two.email, /would like to connect with you/)
      verify_only_delivery(@user_two.email, /matchinggame\.com\/link/)
    end
  end

  describe "notification of other player (college)" do
    before :each do
      @response = Factory.create(:response)
      @combo    = @response.combo
      @combo.update_attributes(:college => Factory(:college))
      @user_one = @combo.photo_one.player.user
      @user_two = @combo.photo_two.player.user
      Delayed::Job.delete_all
    end

    it "should provide links to the facebook app" do
      @response.notify_other_player(:photo_two)
      Delayed::Job.last.invoke_job
      verify_only_delivery(@user_two.email, /apps.facebook.com/)
      ActionMailer::Base.deliveries.first.body.should_not include("matchinggame.com/link")
    end
  end

  describe "#reveal_some" do
    context "three responses, one with a photo each from the other two" do
      before :each do
        @response                        = Factory(:response, :revealed_at => nil, :combo => Factory(:combo, :yes_count => 6, :no_count => 4))
        @another_response_same_photo_one = Factory(:response, :revealed_at => nil, :combo => Factory(:combo, :yes_count => 8, :no_count => 2, :photo_one => @response.combo.photo_one))
        @another_response_same_photo_two = Factory(:response, :revealed_at => nil, :combo => Factory(:combo, :yes_count => 7, :no_count => 3, :photo_two => @response.combo.photo_two))
      end

      it "should start with nil revealed_at times" do
        @response.revealed_at.should be_nil
        @another_response_same_photo_one.revealed_at.should be_nil
        @another_response_same_photo_two.revealed_at.should be_nil
      end

      it "should stagger revealed_at dates into the future if there are multiple responses to reveal" do
        Response.reveal_some

        @another_response_same_photo_one.reload.revealed_at.should <= Time.now
        @another_response_same_photo_two.reload.revealed_at.should <= Time.now
        @response.reload.revealed_at.should > 2.hours.from_now
      end

      it "should use yes_percent to select responses to reveal first" do
        @response.combo.update_attributes(:yes_count => 9, :no_count => 1)

        Response.reveal_some

        @response.reload.revealed_at.should <= Time.now
        @another_response_same_photo_one.reload.revealed_at.should > 2.hours.from_now
        @another_response_same_photo_two.reload.revealed_at.should > 2.hours.from_now
      end

      it "should not reveal the response if someone has already said 'bad match'" do
        @response.combo.update_attributes(:yes_count => 9, :no_count => 1)
        @response.update_attributes(:photo_two_answer => "bad")

        Response.reveal_some

        @response.reload.revealed_at.should be_nil
        @another_response_same_photo_one.reload.revealed_at.should <= Time.now
        @another_response_same_photo_two.reload.revealed_at.should <= Time.now
      end
    end
  end
end
