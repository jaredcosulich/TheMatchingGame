require 'spec_helper'
require 'spec_helper'

describe Combo do
  describe "find_or_create_by_photos" do
    it "should create if not found, find if created" do

      p1 = Factory.create(:male_photo)
      p2 = Factory.create(:female_photo)

      combo = Combo.find_or_create_by_photo_ids(p1.id, p2.id)

      [p1, p2].should be_include(combo.photo_one)
      [p1, p2].should be_include(combo.photo_two)
      combo.photo_two.should_not == combo.photo_one
      combo.should == Combo.find_or_create_by_photo_ids(p1.id, p2.id)
      combo.should == Combo.find_or_create_by_photo_ids(p2.id, p1.id)
    end

    it "should raise if a photo is nil" do
      photo = Factory.create(:photo)
      proc{Combo.find_or_create_by_photo_ids(photo.id, nil)}.should raise_error
      proc{Combo.find_or_create_by_photo_ids(nil, photo.id)}.should raise_error
    end
  end

  describe "validation" do
    it "should not be valid if photos are same gender" do
      male_photo_one = Factory(:male_photo)
      male_photo_two = Factory(:male_photo)
      combo = Factory.build(:combo, :photo_one => male_photo_one, :photo_two => male_photo_two)
      combo.should_not be_valid
      combo.errors_on(:photo_two).should be_present
    end
  end

  describe "as_json" do
    describe "training" do
      it "should be true if good match" do
        Factory(:good_response).combo.as_json[:results].should == true
      end
      it "should be false if bad match" do
        Factory(:bad_response).combo.as_json[:results].should == false
      end
    end
    describe "predicted" do
      before :each do
        @combo = Factory.create(:combo, :yes_count => 32, :no_count => 83)
      end

      it "should look like json" do
        @combo.as_json.should == {
          :id => @combo.id,
          :one => @combo.photo_one.image.url,
          :one_interests => "",
          :two => @combo.photo_two.image.url,
          :two_interests => "",
          :results => {:yes => 32, :no => 83},
          :cresults => {:yes => 32, :no => 83},
          :choco => @combo.choco,
          :college_id => nil,
          :verified => @combo.verified?
        }
      end

      it "should be used in to_json" do
        from_json = JSON.parse(@combo.to_json)
        from_json["id"].should == @combo.id
        from_json["results"]["yes"].should == 32
      end
    end
  end

  describe "choco" do
    it "should fudge based on mod combo id" do
      unanimous_no = Factory.create(:combo, :yes_count => 0, :no_count => 3)
      unanimous_yes = Factory.create(:combo, :yes_count => 3, :no_count => 0)

      unanimous_no.yes_percent.should == 0
      unanimous_no.yes_choco.should satisfy {|choco| choco > 0}
      unanimous_no.no_choco.should satisfy {|choco| choco < 100}
      (unanimous_no.yes_choco + unanimous_no.no_choco).should == 100 
      unanimous_no.choco.should_not == unanimous_yes.choco
    end
  end

  describe "add_answer" do
    before :each do
      @combo = Factory.create(:combo, :yes_count => 2, :no_count => 2)

    end

    it "should update the count of a given response and the yes percentage" do
      @combo.add_answer("y")
      @combo.no_count.should == 2
      @combo.yes_count.should == 3
      @combo.yes_percent.should == 60
    end

    it "should update the count of a given response and the yes percentage with n" do
      @combo.add_answer("n")
      @combo.no_count.should == 3
      @combo.yes_count.should == 2
      @combo.yes_percent.should == 40
    end
  end

  describe "response state" do
    before :each do
      @combo = Factory.create(:combo, :yes_count => 2, :no_count => 2)
      @response = Factory.create(:response, :combo => @combo)
      @player_one = @combo.photo_one.player
      @player_two = @combo.photo_two.player
    end

    it "should initially be 'unanswered'" do
      @combo.response_state(@player_one).should == "unanswered"
      @combo.response_state(@player_two).should == "unanswered"
    end

    it "should be 'good' or 'bad' once answered" do
      @response.update_attribute(:photo_one_answer, "good")
      @combo.reload
      @combo.response_state(@player_one).should == "good"
      @combo.response_state(@player_two).should == "unanswered"

      @response.update_attribute(:photo_two_answer, "bad")
      @combo.reload
      @combo.response_state(@player_one).should == "good"
      @combo.response_state(@player_two).should == "bad"
    end

    it "should be 'interested' or 'uninterested' if the user wants connect" do
      @response.update_attribute(:photo_one_answer, "interested")
      @combo.reload
      @combo.response_state(@player_one).should == "interested"
      @combo.response_state(@player_two).should == "unanswered"

      @response.update_attribute(:photo_two_answer, "uninterested")
      @combo.reload
      @combo.response_state(@player_one).should == "interested"
      @combo.response_state(@player_two).should == "uninterested"
    end

    it "should consider answer over connect" do
      @response.update_attribute(:photo_one_answer, "good")
      @combo.reload
      @combo.response_state(@player_one).should == "good"

      @response.update_attribute(:photo_one_answer, "interested")
      @combo.reload
      @combo.response_state(@player_one).should == "interested"

      @response.update_attribute(:photo_one_answer, "")
      @combo.reload
      @combo.response_state(@player_one).should == "unanswered"

      @response.update_attribute(:photo_one_answer, "bad")
      @combo.reload
      @combo.response_state(@player_one).should == "bad"
    end

    it "should be empty if for another user" do
      @combo.response_state(Factory.create(:user)).should be_blank
    end

    it "should be unanswered if no response" do
      combo = Factory.create(:combo, :yes_count => 2, :no_count => 2)
      combo.response_state(combo.photo_one.player).should == "unanswered"
    end

  end

  describe "status" do
    before :each do
      @combo = Factory.create(:combo, :active => true)
    end

    it "should start as collecting" do
      @combo.status.should == :collecting
    end

    describe "without response" do
      describe "active" do
        it "should be a bad match if low enough yes_percent" do
          @combo.update_attributes(:no_count => 6, :yes_count => 1)
          @combo.status.should == :bad_active
        end

        it "should be an unlikely match" do
          @combo.update_attributes(:no_count => 3, :yes_count => 2)
          @combo.status.should == :unlikely_active
        end

        it "should be a good match if high enough yes_percent" do
          @combo.update_attributes(:no_count => 1, :yes_count => 6)
          @combo.status.should == :good_active
        end
      end

      describe "inactive" do
        before :each do
          @combo.update_attribute(:active, false)
        end

        describe "with no response" do
          it "should be a bad match if low enough yes_percent" do
            @combo.update_attributes(:no_count => 6, :yes_count => 1)
            @combo.status.should == :bad_inactive
          end

          it "should be an unlikely match" do
            @combo.update_attributes(:no_count => 3, :yes_count => 2)
            @combo.status.should == :unlikely_inactive
          end

          it "should be a good match if high enough yes_percent" do
            @combo.update_attributes(:no_count => 1, :yes_count => 6)
            @combo.status.should == :good_inactive
          end
        end

      end
    end

    describe "response queries" do
      before :each do        
        @your_photo = Factory.create(:male_photo)
        @combo_1a = Factory.create(:combo, :yes_count => 1, :photo_one => @your_photo)
        @combo_1b = Factory.create(:combo, :yes_count => 2, :photo_one => @your_photo)
        @combo_1c = Factory.create(:combo, :yes_count => 3, :photo_one => @your_photo)
        @combo_2a = Factory.create(:combo, :yes_count => 4, :photo_two => @your_photo, :photo_one => Factory(:female_photo))
        @combo_2b = Factory.create(:combo, :yes_count => 5, :photo_two => @your_photo, :photo_one => Factory(:female_photo))
        @combo_2c = Factory.create(:combo, :yes_count => 6, :photo_two => @your_photo, :photo_one => Factory(:female_photo))
        @combo_1a_you_respond = Factory.create(:response, :combo => @combo_1a, :photo_one_answer => "interested")
        @combo_2a_you_respond = Factory.create(:response, :combo => @combo_2a, :photo_two_answer => "bad")
        @combo_1b_they_respond = Factory.create(:response, :combo => @combo_1b, :photo_two_answer => "interested")
        @combo_1c_they_respond = Factory.create(:response, :combo => @combo_1c, :photo_two_answer => "uninterested")
        @combo_2b_both_respond = Factory.create(:response, :combo => @combo_2b, :photo_one_answer => "interested", :photo_two_answer => "interested")
        @another = Factory.create(:response)
      end

      it "should deliver photos that you have responded to" do
        Combo.with_responses_for([@your_photo], nil).should == [@combo_2b, @combo_2a, @combo_1a]
      end

      it "should deliver photos that you have responded to in a specific way" do
        Combo.with_responses_for([@your_photo], ['bad']).should == [@combo_2a]
      end

      it "should deliver photos that they have responded to, but you have not" do
        Combo.awaiting_responses_for(@your_photo, nil).should == [@combo_1c, @combo_1b]
      end

      it "should deliver photos that they have responded to in a specific way, but you have not" do
        Combo.awaiting_responses_for(@your_photo, 'interested').should == [@combo_1b]
      end

      it "should deliver photos that you have not responded to" do
        Combo.without_responses_for(@your_photo).should == [@combo_2c, @combo_1c, @combo_1b]
      end

    end

    describe "with response" do
      before :each do
        @response = Factory.create(:response, :combo => @combo)
        @combo.photo_one.update_attribute(:gender, "f")
        @combo.photo_two.update_attribute(:gender, "m")
      end

      STATUS_SPECS = [
        [nil,          nil,          :good_inactive],
        [nil,          "bad",        :no_hn],
        [nil,          "good",       :likely_hy],
        [nil,          "interested", :likely_hy],
        ["bad",        nil,          :no_sn],
        ["bad",        "bad",        :no_bn],
        ["bad",        "good",       :no_hy_sn],
        ["bad",        "interested", :no_hy_sn],
        ["good",       nil,          :likely_sy],
        ["good",       "bad",        :no_sy_hn],
        ["good",       "good",       :match],
        ["good",       "interested", :match],
        ["interested", nil,          :likely_sy],
        ["interested", "bad",        :no_sy_hn],
        ["interested", "good",       :match],
        ["interested", "interested", :match]
      ]

      STATUS_SPECS.each do |status_spec|
        it "should handle #{status_spec[2]}" do
          @response.update_attributes(:photo_one_answer => status_spec[0], :photo_two_answer => status_spec[1])
          @combo.reload.status.should == status_spec[2]
        end
      end
    end

    describe "sort by other response" do
      it "should sort by other interested, uninterested, good, bad, nil" do
        photo = Factory.create(:photo)
        no_response =           Factory.create(:response, :combo => Factory.create(:combo, :photo_one => photo))
        good_response =         Factory.create(:response, :combo => Factory.create(:combo, :photo_one => photo), :photo_two_answer => "good")
        bad_response =          Factory.create(:response, :combo => Factory.create(:combo, :photo_one => photo), :photo_two_answer => "bad")
        interested_response =   Factory.create(:response, :combo => Factory.create(:combo, :photo_one => photo), :photo_two_answer => "interested")
        uninterested_response = Factory.create(:response, :combo => Factory.create(:combo, :photo_one => photo), :photo_two_answer => "uninterested")

        combos = [no_response, good_response, bad_response, interested_response, uninterested_response].collect{|r|r.combo.reload}

        combos.sort{ |a,b| b.points_for_other_answer(photo) <=> a.points_for_other_answer(photo) }.should == [interested_response.combo, uninterested_response.combo, good_response.combo, bad_response.combo, no_response.combo]
      end
    end

  end

  describe "lifecycle" do
    it "should record an inactivated_at date and state_changed_at date" do
      ActiveRecord::Observer.with_observers(:combo_observer) do
        combo = Factory.create(:combo, :yes_count => 8, :no_count => 8)
        combo.save!

        combo.should_not be_active
        combo.reload.inactivated_at.should_not be_nil
        combo.reload.state_changed_at.should == combo.reload.inactivated_at
      end
    end

    it "should update state_changed_at when a response is created" do
      combo = Factory.create(:combo, :yes_count => 8, :no_count => 8)
      response = combo.create_response(:photo_one_answer => 'good')

      combo.reload.state_changed_at.to_s.should == response.created_at.to_s
    end

    it "should update state_changed_at when a response is updated" do
      response = Factory.create(:response)
      response.update_attribute(:photo_two_answer, 'bad')
      response.combo.state_changed_at.should == response.updated_at
    end
  end

end

