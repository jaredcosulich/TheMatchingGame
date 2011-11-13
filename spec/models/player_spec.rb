require 'spec_helper'

describe Player do
  describe "recent games" do
    before :each do
      @player = Factory.create(:player)
    end

    it "should filter out games with no answers" do
      Factory.create(:game, :player => @player)
      with_answers = Factory.create(:game, :player => @player)
      Factory.create(:answer, :game => with_answers)
      Factory.create(:game, :player => @player)

      @player.games.count.should == 3
      @player.recent_games.should == [with_answers]
    end

    it "should show most recent first" do
      first = Factory.create(:answer, :game => Factory.create(:game, :player => @player)).game
      second = Factory.create(:answer, :game => Factory.create(:game, :player => @player)).game

      @player.recent_games.should == [second, first]
    end
  end

  describe "migrate games from other player" do
    before(:each) do
      @game_1_1 = Factory.create(:game)
      @player_1 = @game_1_1.player
      @game_1_2 = Factory.create(:game, :player => @player_1)
      @game_1_3 = Factory.create(:game, :player => @player_1)
      Factory.create(:answer, :game => @game_1_1)
      Factory.create(:answer, :game => @game_1_2)
      Factory.create(:answer, :game => @game_1_3)
      @answer_game_1_1 = @game_1_1.answers[0]
      @answer_game_1_2 = @game_1_2.answers[0]
      @answer_game_1_3 = @game_1_3.answers[0]

      @game_2_1 = Factory.create(:game)
      @player_2 = @game_2_1.player
      @game_2_2 = Factory.create(:game, :player => @player_2)
      Factory.create(:answer, :game => @game_2_1)
      Factory.create(:answer, :game => @game_2_2)
    end

    it "should move all answers from other player's games to this player's games and not destroy other player's games" do
      @player_2.migrate_games_from(@player_1.id)
      @player_2.games.length.should == 3
      @player_2.games.last.should_not == @game_2_2
      @player_2.games.last.answers.length.should == 3
      @player_1.answers.length.should == 0
      @answer_game_1_1.reload.game.should == @player_2.games.last
      @answer_game_1_2.reload.game.should == @player_2.games.last
      @answer_game_1_3.reload.game.should == @player_2.games.last

      Player.find_by_id(@player_1.id).should_not be_nil
      @game_1_1.reload.player.should == @player_1
      @game_1_1.reload.answers.length.should == 0
      @game_1_2.reload.player.should == @player_1
      @game_1_2.reload.answers.length.should == 0
      @game_1_3.reload.player.should == @player_1
      @game_1_3.reload.answers.length.should == 0
    end

    it "should not migrate if other player has a user" do
      Factory.create(:user, :player => @player_1)
      @player_2.migrate_games_from(@player_1.id)
      @player_2.games.length.should == 2
      Player.find_by_id(@player_1.id).should == @player_1
      @game_1_1.reload.player.should == @player_1
      @game_1_1.reload.answers.length.should == 1
      @game_1_2.reload.player.should == @player_1
      @game_1_2.reload.answers.length.should == 1
      @game_1_3.reload.player.should == @player_1
      @game_1_3.reload.answers.length.should == 1

      @answer_game_1_1.reload.game.should == @game_1_1
      @answer_game_1_2.reload.game.should == @game_1_2
      @answer_game_1_3.reload.game.should == @game_1_3
    end

    it "should not migrate if other player does not exist" do
      @player_2.migrate_games_from(99999)
      @player_2.games.length.should == 2
    end

    it "should not migrate if other player does not exist" do
      @player_2.migrate_games_from(nil)
      @player_2.games.length.should == 2
    end

    it "should not migrate over a duplicate answer" do
      duplicate_answer = Factory.create(:answer, :game => @game_2_1, :combo => @answer_game_1_1.combo)
      @player_2.migrate_games_from(@player_1.id)
      @player_2.games.last.answers.length.should == 2
      @player_1.answers.length.should == 1
      duplicate_answer.reload.game.should == @game_2_1
      @answer_game_1_1.reload.game.should == @game_1_1
      @game_1_1.reload.answers.length.should == 1
    end

    it "should not migrate over answers with your photo" do
      player_in_combo = @answer_game_1_1.combo.photo_one.player
      player_in_combo.answers.should be_empty

      player_in_combo.migrate_games_from(@player_1.id)

      @answer_game_1_1.reload.game.player.should == @player_1
      player_in_combo.reload.answers.sort.should == [@answer_game_1_2, @answer_game_1_3]
    end
  end

  describe "update_from_facebook" do
    before :each do
      @player = Factory.create(:admin).player
    end

    it "should create a facebook_profile" do
      @player.update_from_facebook({:id => 15700, :first_name => "Jared", :current_location => {:name => "Concord, MA"}})

      @player.reload
      @player.first_name.should == "Jared"
      @player.location_name.should == "Concord, MA"
      @player.preferred_profile.should == @player.facebook_profile
    end

    it "should update a facebook_profile" do
      Factory.create(:profile, :player => @player)
      Factory.create(:facebook_profile, :player => @player)
      Player.count.should == 1
      Profile.count.should == 1
      FacebookProfile.count.should == 1

      @player.facebook_profile.first_name.should == "Adam"

      @player.update_from_facebook({:uid => 15700, :first_name => "Jared", :current_location => {:name => "Concord, MA"}, :sex => "male"})

      @player.reload

      @player.facebook_profile.first_name.should == "Jared"
      @player.facebook_profile.location_name.should == "Concord, MA"
      @player.preferred_profile.should == @player.profile
    end

    it "should update gender" do
      @player.update_from_facebook(:id => 15700, :sex => "female")

      @player.reload.gender.should == "f"
    end

    it "should set email" do
      @player.user.update_attribute(:email, "fb_123@thematchinggame.com")

      @player.update_from_facebook(:id => 15700, :email => "jared.cosulich@gmail.com")

      @player.reload.email.should == "jared.cosulich@gmail.com"
    end

    it "should not overwrite email?" do
      @player.user.update_attribute(:email, "jared@thematchinggame.com")

      @player.update_from_facebook(:id => 15700, :email => "jared.cosulich@gmail.com")

      @player.reload.email.should == "jared@thematchinggame.com"
    end

    it "should raise if fb_id conflicts or missing" do
      lambda {@player.update_from_facebook(:id => 123, :email => "jared.cosulich@gmail.com")}.should raise_error
      lambda {@player.update_from_facebook(:uid => 123, :email => "jared.cosulich@gmail.com")}.should raise_error
      lambda {@player.update_from_facebook(:email => "jared.cosulich@gmail.com")}.should raise_error
    end

    it "should not raise if fb_id on user is nil" do
      @player.user.update_attribute(:fb_id, nil)
      lambda {@player.update_from_facebook(:id => 123, :email => "jared.cosulich@gmail.com")}.should_not raise_error
    end
  end

  describe "becoming connectable" do
    before :each do
      @response = Factory.create(:response)
      @combo = @response.combo
      @user_one = @combo.photo_one.player.user
      @user_two = @combo.photo_two.player.user

      @user_one.player.update_attribute(:connectable, false)
      @response.reload

      Delayed::Job.delete_all
    end

    it "should email old good mutual matches" do
      @response.update_attribute(:photo_one_answer, "good")
      @response.update_attribute(:photo_two_answer, "good")
      Delayed::Job.delete_all

      @user_one.player.update_attribute(:connectable, true)
      Delayed::Job.all.each { |j| j.invoke_job }

      ActionMailer::Base.deliveries.length.should == 2
      bodies = ActionMailer::Base.deliveries.map(&:body)
      to_addrs = ActionMailer::Base.deliveries.map { |delivery| delivery.to_addrs.first.to_s }
      [@user_one.email, @user_two.email].each { |email| to_addrs.should include(email) }
      bodies.each { |body| body.should =~ /both thought you would be a good match for each other!/ }
    end

    it "should not fail if there is no response on one of the photos combos" do
      @combo = Factory.create(:combo, :photo_one => @combo.photo_one)
      @user_one.player.update_attribute(:connectable, true)
    end

    it "should not email old good non-mutual matches" do
      @response.update_attribute(:photo_one_answer, "bad")
      @response.update_attribute(:photo_two_answer, "good")
      Delayed::Job.delete_all

      @user_one.player.update_attribute(:connectable, true)
      Delayed::Job.count.should == 0      
    end

    it "should not email if already connectable" do
      @user_one.player.update_attribute(:connectable, true)
      @response.reload
      @response.update_attribute(:photo_one_answer, "good")
      @response.update_attribute(:photo_two_answer, "good")
      Delayed::Job.delete_all

      @user_one.player.update_attribute(:connectable, true)
      Delayed::Job.count.should == 0
    end
  end

  describe "age_score" do
    def player_with_gender_and_age(gender, age)
      player = Factory(:player, :gender => gender)
      player.create_profile(:birthdate => age.years.ago)
      player.reload
    end

    it "should be a point for every 2.5 years the male is older, and 1 point for every 1 years the female is older" do
      male = player_with_gender_and_age("m", 30)

      (20..40).each.collect do |age|
        male.age_score(player_with_gender_and_age("f", age))
      end.should == [4,3,3,2,2,2,1,1,0,0,0,1,2,3,4,5,6,7,8,9,10]

    end
  end

  describe "distance_score" do
    def player_with_gender_and_lat_lng(gender, lat, lng)
      player = Factory(:player, :gender => gender, :geo_lat => lat, :geo_lng => lng)
      player.reload
    end

    it "should be -1 if in exact same spot" do
      male = player_with_gender_and_lat_lng("m", 10, 10)
      female_in_same_location = player_with_gender_and_lat_lng("f", 10, 10)
      male.distance_score(female_in_same_location).should == -1
    end
  end

  describe "lat_lng" do
    it "should use profile lat/lng" do
      player = Factory(:player, :geo_lat => 11.11, :geo_lng => 22.22)
      player.create_profile(:location_lat => 33.3, :location_lng => -66.6)

      player.lat_lng.ll.should == "33.3,-66.6"
    end

    it "should use player lat/lng if profile lat/lng blank" do
      player = Factory(:player, :geo_lat => 11.11, :geo_lng => 22.22)
      player.create_profile(:birthdate => 20.years.ago)

      player.lat_lng.ll.should == "11.11,22.22"
    end

    it "should use player lat/lng if no profile" do
      player = Factory(:player, :geo_lat => 11.11, :geo_lng => 22.22)
      player.create_profile(:birthdate => 20.years.ago)

      player.lat_lng.ll.should == "11.11,22.22"

    end

    xit "should geocode user IP if no profile or player info" do
      Geokit::Geocoders::MultiGeocoder.should_receive(:geocode).and_return(GeoKit::LatLng.new(99.999, 88.888))
      player = Factory(:player)
      player.create_user(:current_login_ip => "1.2.3.4")

      player.lat_lng.ll.should == "99.999,88.888"
    end

    it "should default to MO" do
      Player.new.lat_lng.ll.should == Player::DEFAULT_LAT_LNG.ll
    end

  end

  describe "update_interests" do
    before :each do
      @interests = ["interest1", "interest2", "interest3", "interest4"]
      @player = Factory(:player)
      @player.update_interests(@interests.collect { |interest| {:title => interest }})
      @player.reload
    end

    it "should create new interests" do
      @player.interests.map(&:title).should =~ @interests
    end

    it "should not create duplicate interests and should remove if not in update" do
      latest_interests = ["interest1", "interest2", "interest6", "interest7"]
      @player.update_interests(latest_interests.collect { |interest| {:title => interest }})
      @player.reload
      @player.interests.map(&:title).should =~ latest_interests
    end

    it "should not create duplicate interests if passed in in the same update" do
      latest_interests = @interests * 3
      @player.update_interests(latest_interests.collect { |interest| {:title => interest }})
      @player.reload
      @player.interests.map(&:title).should =~ @interests
    end

    it "should not accept blank interests" do
      latest_interests = ["", "", ""]
      @player.update_interests(latest_interests.collect { |interest| {:title => interest }})
      @player.reload
      @player.interests.should be_empty
    end
  end

  describe "same sex" do
    it "should be set to false by default" do
      player = Factory(:player)
      player.should_not be_same_sex
    end
  end

  describe "badges" do
    before :each do
      @player = Factory(:registered_player)
      @correct_count = 0
      @player.player_stat.should_receive(:correct_count).any_number_of_times.and_return { @correct_count }
    end

    it "should have a 5_correct_badge if you have 5 correct answers" do
      @correct_count = 6
      @player.all_badge_icons.should == ["5_correct_badge"]
    end

    it "should have a 5_correct_badge if you have 20 correct answers" do
      @correct_count = 20
      @player.all_badge_icons.should == ["20_correct_badge", "5_correct_badge"]
    end

    it "should not receive a correct_badge if less than 5 correct answers" do
      @correct_count = 3
      @player.all_badge_icons.should == []
    end
  end

end
