require 'spec_helper'

describe ChallengePlayer do
  before :each do
    @challenge = Factory.create(:challenge, :invitation_text => "Invitation Text")
  end

  describe "invitations" do
    it "should email the creator" do
      verify_only_delayed_delivery(@challenge.creator.email, /The following message was emailed to all challengers with a link to the challenge/)
    end

    it "should email invited players" do
      Delayed::Job.delete_all
      @challenge.challenge_players.create(:name => "Example Player", :email => "example@example.com")

      verify_only_delayed_delivery("example@example.com", /Invitation Text/)
    end

    it "should require name and valid email" do
      new_player = @challenge.challenge_players.new
      new_player.should_not be_valid

      another_player = @challenge.challenge_players.new(:name => "John Smith")
      another_player.should_not be_valid
      another_player.errors_on(:email).should be_present

      yet_another_player = @challenge.challenge_players.new(:email => "john@example.com")
      yet_another_player.should_not be_valid
      yet_another_player.errors_on(:name).should be_present
      

      bad_email_player = @challenge.challenge_players.new(:email => "!!!")
      bad_email_player.should_not be_valid
      bad_email_player.errors_on(:email).should be_present
    end

    it "should connect to existing users" do
      user = Factory.create(:user, :email => "user@example.com")

      challenge_player = @challenge.challenge_players.create(:name => "Example Player", :email => "user@example.com")

      challenge_player.player.should == user.player

    end

    it "should invite facebook players"
  end

  describe "completion" do
    before :each do
      @good_combo = Factory.create(:good_response).combo
      @bad_combo = Factory.create(:bad_response).combo
      @challenge = Factory.create(:challenge)
      
      @challenge_player_one = @challenge.challenge_players.create!(:name => "playerOneName", :email => "challengedOne@example.com")
      @challenge_player_one.find_or_create_player

      @challenge_player_two = @challenge.challenge_players.create!(:name => "playerTwoName", :email => "challengedTwo@example.com")
      @challenge_player_two.find_or_create_player
    end

    it "should send an email to the creator as each player completes" do
      Delayed::Job.delete_all
      ActiveRecord::Observer.with_observers(:game_observer) do
        game = @challenge_player_one.create_game

        game.answers.create(:answer => "y", :combo => @good_combo)
        Delayed::Job.count.should == 0

        game.answers.create(:answer => "y", :combo => @bad_combo)
        verify_only_delayed_delivery(@challenge.creator.email, /playerOneName/)
      end
    end

    it "should send a different email to everyone when the full challenge completes" do
      Delayed::Job.delete_all
      ActiveRecord::Observer.with_observers(:game_observer) do
        game = @challenge_player_one.create_game
        game.answers.create(:answer => "y", :combo => @good_combo)
        game.answers.create(:answer => "y", :combo => @bad_combo)
        Delayed::Job.all.only.delete

        game2 = @challenge.challenge_player_for(@challenge.creator).create_game
        game2.answers.create(:answer => "y", :combo => @good_combo)
        game2.answers.create(:answer => "y", :combo => @bad_combo)
        Delayed::Job.all.only.delete
        
        game3 = @challenge_player_two.create_game
        game3.answers.create(:answer => "n", :combo => @good_combo)
        game3.answers.create(:answer => "n", :combo => @bad_combo)

        Delayed::Job.count.should == 3
        Delayed::Job.all.each { |j| j.invoke_job }

        messages = ActionMailer::Base.deliveries
        messages.length.should == 3
        messages.map { |m| m.to_addrs.to_s }.should include("challengedOne@example.com")
        messages.map { |m| m.to_addrs.to_s }.should include("challengedTwo@example.com")

        messages.each { |m| m.body.should =~ /won the challenge/ }
      end
    end

    it "should send a different email to everyone if only unplayed player is removed" do
      Delayed::Job.delete_all
      ActiveRecord::Observer.with_observers(:game_observer) do
        game = @challenge_player_one.create_game
        game.answers.create(:answer => "y", :combo => @good_combo)
        game.answers.create(:answer => "y", :combo => @bad_combo)
        Delayed::Job.all.only.delete

        game2 = @challenge.challenge_player_for(@challenge.creator).create_game
        game2.answers.create(:answer => "y", :combo => @good_combo)
        game2.answers.create(:answer => "y", :combo => @bad_combo)
        Delayed::Job.all.only.delete

        @challenge_player_two.destroy

        Delayed::Job.all.each { |j| j.invoke_job }

        messages = ActionMailer::Base.deliveries
        messages.length.should == 2
        messages.map { |m| m.to_addrs.to_s }.should include("challengedOne@example.com")
        messages.map { |m| m.to_addrs.to_s }.should_not include("challengedTwo@example.com")

        messages.each { |m| m.body.should =~ /won the challenge/ }
      end
    end
  end
end
