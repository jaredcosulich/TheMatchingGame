require 'spec_helper'

describe ResponseObserver do
  before :each do
    @combo = Factory.create(:combo)
    @answer_y = Factory.create(:answer, :answer => "y", :combo => @combo)
    @answer_n = Factory.create(:answer, :answer => "n", :combo => @combo)

    @answer_y.game.player.score_events.should be_empty
    @answer_n.game.player.score_events.should be_empty
  end

  it "should create response events for all predicting answers" do
    ActiveRecord::Observer.with_observers(:response_observer, :combo_observer) do
      response = Factory.create(:response, :combo => @combo, :photo_one_answer => "bad")
      response.save!
      response.should be_verified_bad

      work_all_jobs

      event_for_yes = @answer_y.game.player.reload.score_events.only
      event_for_yes.correct_count.should == 0
      event_for_yes.incorrect_count.should == 1

      event_for_no = @answer_n.game.player.reload.score_events.only
      event_for_no.correct_count.should == 1
      event_for_no.incorrect_count.should == 0
    end
  end

  it "should not create response events if the response does not become verified" do
    ActiveRecord::Observer.with_observers(:response_observer) do
      response = Factory.create(:response, :combo => @combo, :photo_one_answer => "good")
      response.save!
      response.should_not be_verified

      work_all_jobs

      @answer_y.game.player.reload.score_events.should be_empty
      @answer_n.game.player.reload.score_events.should be_empty
    end
  end

  it "should remove score_events if response becomes unverified" do
    ActiveRecord::Observer.with_observers(:response_observer) do
      response = Factory.create(:response, :combo => @combo, :photo_one_answer => "bad")
      response.save!
      response.should be_verified

      work_all_jobs

      @answer_y.game.player.reload.score_events.count.should == 1
      @answer_n.game.player.reload.score_events.count.should == 1

      response.update_attribute(:photo_one_answer, "good")
      response.should_not be_verified

      work_all_jobs

      @answer_y.game.player.score_events.should be_empty
      @answer_n.game.player.score_events.should be_empty
    end

  end

  it "should update score_events if response verified changes" do
    ActiveRecord::Observer.with_observers(:response_observer) do
      response = Factory.create(:response, :combo => @combo, :photo_one_answer => "good", :photo_two_answer => "good")
      response.save!

      work_all_jobs

      response.should be_verified_good
      @answer_y.game.player.reload.score_events.only.correct_count.should == 1
      @answer_n.game.player.reload.score_events.only.correct_count.should == 0

      response.reload
      response.update_attribute(:photo_one_answer, "bad")
      response.should be_verified_bad

      work_all_jobs

      @answer_y.game.player.reload.score_events.only.correct_count.should == 0
      @answer_n.game.player.reload.score_events.only.correct_count.should == 1
    end
  end

  it "should not create score_events, but should update game_event counts for existing answers" do
    ActiveRecord::Observer.with_observers(:response_observer, :game_observer) do
      response = Factory.create(:response, :combo => @combo, :photo_one_answer => "good", :photo_two_answer => "good")
      response.save!

      work_all_jobs

      @combo.reload
      response.should be_verified_good
      existing_answer = Factory.create(:answer, :answer => "y", :combo => @combo)

      @answer_y.game.player.reload.score_events.select { |s| s.is_a?(ResponseEvent) }.only.correct_count.should == 1
      existing_answer.game.player.reload.score_events.select { |s| s.is_a?(GameEvent) }.only.correct_count.should == 1

      response.reload
      response.update_attribute(:photo_one_answer, "bad")
      response.should be_verified_bad

      work_all_jobs

      @answer_y.game.player.reload.score_events.select { |s| s.is_a?(ResponseEvent) }.only.correct_count.should == 0
      existing_answer.game.player.reload.score_events.select { |s| s.is_a?(ResponseEvent) }.should be_empty
      existing_answer.game.player.reload.score_events.select { |s| s.is_a?(GameEvent) }.only.correct_count.should == 0
    end

  end

  it "should update PhotoPairs" do
    ActiveRecord::Observer.with_observers(:response_observer) do
      PhotoPair.create_or_refresh_by_combo(@combo)
      PhotoPair.all.map(&:response).should == [0,0]
      PhotoPair.all.map(&:other_response).should == [0,0]

      response = Factory.create(:response, :combo => @combo, :photo_one_answer => "good", :photo_two_answer => "good")
      response.save!
      work_all_jobs

      PhotoPair.all.map(&:response).should == [1,1]
      PhotoPair.all.map(&:other_response).should == [1,1]
    end
  end
end
