require 'spec_helper'

describe MatchMeAnswerObserver do
  before :each do
    @photo = Factory(:male_photo)
    @other_photo = Factory(:female_photo)
  end

  describe "after create" do

    it "should create PhotoPairs" do
      ActiveRecord::Observer.with_observers(:match_me_answer_observer) do
        PhotoPair.count.should == 0

        MatchMeAnswer.create!(:target_photo => @photo, :other_photo => @other_photo, :answer => "y", :player => @photo.player)
        work_all_jobs

        PhotoPair.count.should == 2
      end
    end

    it "should update existing PhotoPairs" do
      ActiveRecord::Observer.with_observers(:match_me_answer_observer) do
        PhotoPair.create!(:photo_id => @photo.id, :other_photo_id => @other_photo.id)
        PhotoPair.all.only.photo_answer_yes.should == 0

        MatchMeAnswer.create!(:target_photo => @photo, :other_photo => @other_photo, :answer => "y", :player => @photo.player)
        work_all_jobs

        PhotoPair.count.should == 2
        photo_pairs = PhotoPair.order("created_at asc")
        photo_pairs.map(&:photo_answer_yes).should == [1, 0]
        photo_pairs.map(&:other_photo_answer_yes).should == [0, 1]
      end
    end

    it "should create a combo and response if it completes a mutual good" do
      ActiveRecord::Observer.with_observers(:match_me_answer_observer, :combo_observer) do
        MatchMeAnswer.create!(:target_photo => @photo, :other_photo => @other_photo, :answer => "y", :player => @photo.player)
        work_all_jobs

        Combo.count.should == 0
        Response.count.should == 0

        MatchMeAnswer.create!(:target_photo => @other_photo, :other_photo => @photo, :answer => "y", :player => @other_photo.player)
        work_all_jobs

        combo = Combo.all.only
        combo.should_not be_active
        combo.yes_choco.should > 75
        combo.creation_reason.should == "mutual_match_me"
        [combo.photo_one, combo.photo_two].should =~ [@photo, @other_photo]

        combo.response.should be_present
        combo.response.creation_reason.should == "mutual_match_me"

        PhotoPair.count.should == 2
        PhotoPair.all.map(&:combo_id).should =~ [combo.id, combo.id]
      end
    end

    it "should create a response but not combo if it completes a mutual good but a combo exists" do
      ActiveRecord::Observer.with_observers(:match_me_answer_observer, :combo_observer) do
        MatchMeAnswer.create!(:target_photo => @photo, :other_photo => @other_photo, :answer => "y", :player => @photo.player)
        Combo.create!(:photo_one => @photo, :photo_two => @other_photo, :creation_reason => "combo_reason", :yes_count => 1, :no_count => 6)
        work_all_jobs

        PhotoPair.count.should == 2
        Combo.count.should == 1
        Response.count.should == 0

        MatchMeAnswer.create!(:target_photo => @other_photo, :other_photo => @photo, :answer => "y", :player => @other_photo.player)
        work_all_jobs

        combo = Combo.all.only
        combo.should_not be_active
        combo.yes_choco.should > 75
        combo.creation_reason.should == "combo_reason"
        [combo.photo_one, combo.photo_two].should =~ [@photo, @other_photo]

        combo.response.should be_present
        combo.response.creation_reason.should == "mutual_match_me"

        PhotoPair.count.should == 2
        PhotoPair.all.map(&:combo_id).should =~ [combo.id, combo.id]
      end
    end

    it "should not do anything if a response exists" do
      ActiveRecord::Observer.with_observers(:match_me_answer_observer, :combo_observer) do
        MatchMeAnswer.create!(:target_photo => @photo, :other_photo => @other_photo, :answer => "y", :player => @photo.player)
        combo = Combo.create!(:photo_one => @photo, :photo_two => @other_photo, :creation_reason => "combo_reason", :yes_count => 1, :no_count => 6)
        response = combo.create_response(:creation_reason => "response_reason")
        work_all_jobs

        PhotoPair.count.should == 2
        Combo.count.should == 1
        Response.count.should == 1

        MatchMeAnswer.create!(:target_photo => @other_photo, :other_photo => @photo, :answer => "y", :player => @other_photo.player)
        work_all_jobs

        combo.reload
        combo.response.should == response
        combo.response.creation_reason.should == "response_reason"
      end
    end
  end
end
