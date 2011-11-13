require 'spec_helper'

describe PhotoPair do
  describe "#lookup_stats" do
    before :each do
      @combo = Factory(:combo)
      @photo_pair = PhotoPair.create(:photo => @combo.photo_one, :other_photo => @combo.photo_two, :combo => @combo)
    end

    it "should have starting values" do
      @photo_pair.distance.should == 0
      @photo_pair.age_difference.should be_nil
      @photo_pair.bucket_difference.should == 0

      @photo_pair.photo_answer_yes.should == 0
      @photo_pair.photo_answer_no.should == 0
      @photo_pair.other_photo_answer_yes.should == 0
      @photo_pair.other_photo_answer_no.should == 0

      @photo_pair.friend_answer_yes.should  == 0
      @photo_pair.friend_answer_no.should == 0

      @photo_pair.yes_count.should == 0
      @photo_pair.no_count.should == 0
      @photo_pair.vote_count.should == 0
      @photo_pair.yes_percent.should == 0


      @photo_pair.response.should == 0
      @photo_pair.other_response.should == 0
      @photo_pair.photo_message_count.should == 0
      @photo_pair.other_photo_message_count.should == 0
    end

    it "should pick up match me answers" do
      MatchMeAnswer.create!(:player => @combo.photo_one.player, :target_photo => @combo.photo_one, :other_photo => @combo.photo_two, :answer => "y")
      MatchMeAnswer.create!(:player => @combo.photo_two.player, :target_photo => @combo.photo_two, :other_photo => @combo.photo_one, :answer => "n")
      MatchMeAnswer.create!(:player => Factory(:player), :target_photo => @combo.photo_one, :other_photo => @combo.photo_two, :answer => "y")
      MatchMeAnswer.create!(:player => Factory(:player), :target_photo => @combo.photo_one, :other_photo => @combo.photo_two, :answer => "n")
      MatchMeAnswer.create!(:player => Factory(:player), :target_photo => @combo.photo_two, :other_photo => @combo.photo_one, :answer => "y")

      @photo_pair = PhotoPair.find(@photo_pair.id)
      @photo_pair.lookup_stats

      @photo_pair.photo_answer_yes.should == 1
      @photo_pair.photo_answer_no.should == 0
      @photo_pair.other_photo_answer_yes.should == 0
      @photo_pair.other_photo_answer_no.should == 1
      @photo_pair.friend_answer_yes.should == 2
      @photo_pair.friend_answer_no.should == 1
    end

    it "should pick up answer data" do
      @combo.update_attributes(:yes_count => 3, :no_count => 1)

      @photo_pair = PhotoPair.find(@photo_pair.id)
      @photo_pair.lookup_stats

      @photo_pair.yes_count.should == 3
      @photo_pair.no_count.should == 1
      @photo_pair.vote_count.should == 4
      @photo_pair.yes_percent.should == 75
    end

    it "should pick up response data" do
      @combo.create_response(:photo_one_answer => "good", :photo_two_answer => "bad")

      @photo_pair = PhotoPair.find(@photo_pair.id)
      @photo_pair.lookup_stats

      @photo_pair.response.should == 1
      @photo_pair.other_response.should == -1
    end

    it "should pick up message counts" do
      Factory(:user, :player => @combo.photo_one.player)
      Factory(:user, :player => @combo.photo_two.player)
      @combo.connect(@combo.photo_one, "Hey!")
      @combo.message(@combo.photo_two, "Wassup!")
      @combo.message(@combo.photo_one, "Nada")

      @photo_pair.lookup_stats

      @photo_pair.photo_message_count.should == 2
      @photo_pair.other_photo_message_count.should == 1
    end

    describe "calculating distance" do
      before :each do
        @combo.photo_one.player.update_attributes(:geo_lat => 37.786, :geo_lng => -122.403)
        @combo.photo_two.player.create_profile(:location_lat => 43.825, :location_lng => -110.635)
      end

      it "should use the models if loaded" do
        @photo_pair = PhotoPair.find(@photo_pair.id)
        @photo_pair.photo.player.should_receive(:distance_from).with(@photo_pair.other_photo.player).and_return(999)

        @photo_pair.lookup_stats

        @photo_pair.distance.should == 999
      end

      it "should query the database if not loaded" do
        @photo_pair = PhotoPair.find(@photo_pair.id)

        @photo_pair.should_not be_loaded_photo
        @photo_pair.should_not be_loaded_other_photo

        @photo_pair = PhotoPair.find(@photo_pair.id)
        @photo_pair.lookup_stats

        @photo_pair.distance.should == 743
        @photo_pair.should_not be_loaded_photo
        @photo_pair.should_not be_loaded_other_photo
      end
    end

    describe "calculating age difference" do
      before :each do
        @photo_pair.photo.player.create_profile(:birthdate => 20.years.ago)
        @photo_pair.other_photo.player.create_profile(:birthdate => 25.years.ago)
      end

      it "should use the models if loaded" do
        @photo_pair = PhotoPair.find(@photo_pair.id)
        @photo_pair.photo
        @photo_pair.other_photo
        @photo_pair.should be_loaded_photo
        @photo_pair.should be_loaded_other_photo

        @photo_pair.lookup_stats

        @photo_pair.age_difference.should == 5
      end

      it "should query the database if not loaded" do
        @photo_pair = PhotoPair.find(@photo_pair.id)

        @photo_pair.should_not be_loaded_photo
        @photo_pair.should_not be_loaded_other_photo

        @photo_pair.lookup_stats

        @photo_pair.age_difference.should == 5
        @photo_pair.should_not be_loaded_photo
        @photo_pair.should_not be_loaded_other_photo
      end
    end

    describe "bucket stats" do
      it "should store the bucket difference" do
        @combo.photo_one.update_attribute(:bucket, 2)
        @combo.photo_two.update_attribute(:bucket, 4)

        @photo_pair.lookup_stats

        @photo_pair.bucket_difference.should == -2
      end
    end
  end

  describe "ready_for_response" do
    it "should select pairs which have a response, where the photo has not responded, and revealed_at is not in the future" do
      revealed_combo = Factory(:response, :revealed_at => 1.minute.ago).combo
      photo                  = revealed_combo.photo_one
      combo_without_response = Factory(:combo, :photo_one => photo)
      reveal_in_future = Factory(:response, :revealed_at => 1.hour.from_now, :photo_two_answer => "good", :combo => Factory(:combo, :photo_one => photo)).combo
      already_responded = Factory(:response, :revealed_at => 1.hour.ago, :photo_one_answer => "good", :combo => Factory(:combo, :photo_one => photo)).combo

      [revealed_combo, combo_without_response, reveal_in_future, already_responded].each do |combo|
        PhotoPair.create_or_refresh_by_combo(combo)
      end

      photo.photo_pairs.ready_for_response.map(&:combo_id).should =~ [revealed_combo.id]
    end
  end

  describe "scores" do
    describe "#distance_score" do
      it "should be a -1 for very small distances" do
        PhotoPair.new(:distance => 5).distance_score.should == -1
        PhotoPair.new(:distance => 0).distance_score.should == -1
      end

      it "should be a 0 for very small distances" do
        PhotoPair.new(:distance => 25).distance_score.should == 0
      end

      it "should be 1 for small distances" do
        PhotoPair.new(:distance => 80).distance_score.should == 1
      end

      it "should be 2 for small distances" do
        PhotoPair.new(:distance => 200).distance_score.should == 2
      end
    end
  end

  describe "#reveal_other_photo_matches" do
    it "should set the other_photo_match_revealed_at time" do
      ActiveRecord::Observer.with_observers(:combo_observer) do
        photo_pair = Factory(:photo_pair, :other_photo_answer_yes => 1)
        photo_pair.other_photo_match_revealed_at.should be_nil

        PhotoPair.reveal_other_photo_matches

        photo_pair.reload.other_photo_match_revealed_at.should_not be_nil
        photo_pair.combo.should_not be_nil
        photo_pair.combo.creation_reason.should == "otherphotomatch"
        photo_pair.combo.should_not be_active
      end
    end

    it "should not reveal (for the receiving person) more than 1 photo at a time per player" do
      photo_pair = Factory(:photo_pair, :other_photo => Factory(:female_photo, :bucket => 3), :other_photo_answer_yes => 1)
      second_photo_pair = Factory(:photo_pair, :photo => photo_pair.photo, :other_photo => Factory(:female_photo, :bucket => 4), :other_photo_answer_yes => 1)
      third_photo_pair = Factory(:photo_pair, :photo => photo_pair.photo, :other_photo => Factory(:female_photo, :bucket => 3), :other_photo_answer_yes => 1)

      photo_pair.other_photo_match_revealed_at.should be_nil
      second_photo_pair.other_photo_match_revealed_at.should be_nil
      third_photo_pair.other_photo_match_revealed_at.should be_nil

      PhotoPair.reveal_other_photo_matches

      photo_pair.reload.other_photo_match_revealed_at.should be_nil
      second_photo_pair.reload.other_photo_match_revealed_at.should_not be_nil
      third_photo_pair.reload.other_photo_match_revealed_at.should be_nil
    end

    it "should not reveal (for the receiving person) the same photo to one player more than once" do
      photo_pair = Factory(:photo_pair, :other_photo_answer_yes => 1)
      photo_pair_same_players = Factory(
        :photo_pair,
        :photo => Factory(:male_photo, :player => photo_pair.photo.player),
        :other_photo => Factory(:female_photo, :player => photo_pair.other_photo.player),
        :other_photo_answer_yes => 1
      )

      PhotoPair.reveal_other_photo_matches

      photo_pair.reload.other_photo_match_revealed_at.should_not be_nil
      photo_pair_same_players.reload.other_photo_match_revealed_at.should > 2.weeks.from_now
    end

    it "should not reveal (for the sending person) more than 1 photos at a time per player" do
      photo_pair = Factory(:photo_pair, :photo => Factory(:male_photo, :bucket => 4), :other_photo_answer_yes => 1)
      second_photo_pair = Factory(:photo_pair, :photo => Factory(:male_photo, :bucket => 4), :other_photo => photo_pair.other_photo, :other_photo_answer_yes => 1)
      third_photo_pair = Factory(:photo_pair, :photo => Factory(:male_photo, :bucket => 3), :other_photo => photo_pair.other_photo, :other_photo_answer_yes => 1)

      photo_pair.other_photo_match_revealed_at.should be_nil
      second_photo_pair.other_photo_match_revealed_at.should be_nil
      third_photo_pair.other_photo_match_revealed_at.should be_nil

      PhotoPair.reveal_other_photo_matches

      photo_pair.reload.other_photo_match_revealed_at.should be_nil
      second_photo_pair.reload.other_photo_match_revealed_at.should be_nil
      third_photo_pair.reload.other_photo_match_revealed_at.should_not be_nil
    end

    it "should be able to reveal photos for new players only (less than 2 days old)" do
      photo_pair = Factory(:photo_pair, :photo => Factory(:male_photo, :created_at => 4.days.ago), :other_photo => Factory(:female_photo, :created_at => 4.days.ago), :other_photo_answer_yes => 1)
      second_photo_pair = Factory(:photo_pair, :photo => Factory(:male_photo, :created_at => 1.days.ago), :other_photo => Factory(:female_photo, :created_at => 4.days.ago), :other_photo_answer_yes => 1)
      third_photo_pair = Factory(:photo_pair, :photo => Factory(:male_photo, :created_at => 4.days.ago), :other_photo => Factory(:female_photo, :created_at => 1.days.ago), :other_photo_answer_yes => 1)

      photo_pair.other_photo_match_revealed_at.should be_nil
      second_photo_pair.other_photo_match_revealed_at.should be_nil
      third_photo_pair.other_photo_match_revealed_at.should be_nil

      PhotoPair.reveal_other_photo_matches(true)

      photo_pair.reload.other_photo_match_revealed_at.should be_nil
      second_photo_pair.reload.other_photo_match_revealed_at.should_not be_nil
      third_photo_pair.reload.other_photo_match_revealed_at.should_not be_nil
    end

  end
end
