
require 'spec_helper'

describe Challenge do
  it "should provide a default name" do
    player = Factory.create(:profile, :first_name => "John").player
    challenge = Challenge.new(:creator => player)
    challenge.creator.first_name.should == "John"
    challenge.name.should == "John's Challenge"
  end

  it "should provide a default name when first name blank" do
    player = Factory.create(:profile, :first_name => "").player
    challenge = Challenge.new(:creator => player)
    challenge.name.should == "Matching Challenge"
  end

  it "should set the first challenge_player attributes on the creator if creator.email.blank?" do
    player = Factory.create(:player)
    challenge = Challenge.create!(:creator => player, :challenge_players_attributes => [{:name => "one", :email => "one@example.com"}, {:name => "two", :email => "two@example.com"}])


    challenge.challenge_players.count.should == 2
    challenge.challenge_players.map(&:name).should == ["one", "two"]

    player.reload
    player.user.email.should == "one@example.com"
    player.profile.full_name.should == "one"
  end

  it "should not be valid if creator.email.blank? and no challenge_players" do
    player = Factory.create(:player)
    challenge = Challenge.create(:creator => player, :challenge_players_attributes => [])

    challenge.should_not be_valid
  end

  it "should create challenge players for all rows and ADD one for the creator if creator email present" do
    player = Factory.create(:full_player)
    challenge = Challenge.create!(:creator => player, :challenge_players_attributes => [{:name => player.full_name, :email => player.email}, {:name => "one", :email => "one@example.com"}, {:name => "two", :email => "two@example.com"}])

    challenge.challenge_players.count.should == 3
    challenge.challenge_players.map(&:name).should == ["first", "one", "two"]

    challenge.creator.first_name.should == "first"
  end

  describe "challenge_combos" do
    before :each do
      @good_combo_one = Factory.create(:good_response).combo
      @good_combo_two = Factory.create(:good_response).combo
      @bad_combo_one = Factory.create(:bad_response).combo
      @bad_combo_two = Factory.create(:bad_response).combo
    end

    it "should create challenge combos when created" do
      challenge = Factory.create(:challenge)

      challenge.challenge_combos.length.should == 4
    end

    it "should not include the same photo more than once" do
      Factory.create(:good_response, :combo => Factory.create(:combo, :photo_one => @good_combo_one.photo_one)).combo

      challenge = Factory.create(:challenge)

      challenge.challenge_combos.length.should == 4
    end

    it "should not include the same player more than once" do
      Factory.create(:good_response, :combo => Factory.create(:combo, :photo_one => Factory.create(:photo, :player => @good_combo_one.photo_one.player))).combo

      challenge = Factory.create(:challenge)

      challenge.challenge_combos.length.should == 4
    end

    it "should not include photos of the creator" do
      player = @good_combo_one.photo_one.player
      Factory.create(:profile, :player => player)
      challenge = Factory.create(:challenge, :creator => player)
      challenge.challenge_combos.length.should == 3
      challenge.challenge_combos.map(&:combo).should_not include(@good_combo_one)
    end

    it "should not include photos of any of the players" do
      user = Factory.create(:user, :player => @good_combo_one.photo_one.player)
      challenge = Challenge.create(:creator => Factory.create(:full_player), :challenge_players_attributes => [{:email => user.email, :name => "name"}])
      challenge.challenge_combos.length.should == 3
      challenge.challenge_combos.map(&:combo).should_not include(@good_combo_one)
    end

    it "should not include combos that the challenge players have been assigned in other challenges" do
      full_player = Factory.create(:full_player)
      first_challenge = Challenge.create(:creator => full_player, :challenge_players_attributes => [{:email => full_player.email, :name => full_player.full_name}, {:email => "a@example.com", :name => "name"}])
      first_challenge.challenge_combos.length.should == 4

      good_combo_three = Factory.create(:good_response).combo
      bad_combo_three = Factory.create(:bad_response).combo

      second_challenge = Challenge.create(:creator => Factory.create(:full_player), :challenge_players_attributes => [{:email => full_player.email, :name => "name"}])

      second_challenge.challenge_combos.map(&:combo_id).sort.should == [good_combo_three.id, bad_combo_three.id]
    end

  end
end
