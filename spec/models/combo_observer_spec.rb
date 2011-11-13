require 'spec_helper'

describe ComboObserver do
  it "should update combo_score without blowing up" do
    ActiveRecord::Observer.with_observers(:combo_observer) do
      combo = Factory.create(:combo)
      game = Factory.create(:game)

      game.answers.create(:combo_id => combo.id, :answer => "y")
    end
  end

  describe "after_create" do
    it "should create PhotoPairs" do
      ActiveRecord::Observer.with_observers(:combo_observer) do
        PhotoPair.count.should == 0

        combo = Factory.create(:combo)

        PhotoPair.all.map(&:combo_id).should == [combo.id, combo.id]
      end

    end
  end

  describe "after_save" do
    it "should refresh PhotoPairs" do
      combo = Factory.create(:combo)
      PhotoPair.create_or_refresh_by_combo(combo)

      ActiveRecord::Observer.with_observers(:combo_observer) do
        combo.update_attributes(:yes_count => 3, :no_count => 1)
        work_all_jobs

        PhotoPair.all.map(&:yes_percent).should == [75, 75]
      end

    end
  end

  describe "before_save" do
    describe "checking the votes on the combo" do
      before :each do
        @combo = Factory(:combo)
      end

      context "with 3 no votes" do
        before :each do
          @combo.no_count = 3
          @combo.yes_count = 1
        end

        it "should deactivate the combo" do
          @combo.should be_active

          ActiveRecord::Observer.with_observers(:combo_observer) { @combo.save! }

          @combo.reload.should_not be_active
        end

        it "should not create a response" do
          @combo.response.should be_nil

          ActiveRecord::Observer.with_observers(:combo_observer) { @combo.save! }

          @combo.reload.response.should be_nil
        end
      end

      context "with 4 yes votes" do
        before :each do
          @combo.no_count = 1
          @combo.yes_count = 4
        end

        it "should deactivate the combo"  do
          @combo.should be_active

          ActiveRecord::Observer.with_observers(:combo_observer) { @combo.save! }

          @combo.reload.should_not be_active
        end

        it "should create a response" do
          @combo.response.should be_nil

          ActiveRecord::Observer.with_observers(:combo_observer) { @combo.save! }

          @combo.reload.response.creation_reason.should == "combo_yes"
        end

      end

      context "with many votes" do
        context "more yes than no" do
          before :each do
            @combo.no_count = 7
            @combo.yes_count = 9
          end

          it "should deactivate the combo create a response" do
            @combo.should be_active
            @combo.response.should be_nil

            ActiveRecord::Observer.with_observers(:combo_observer) { @combo.save! }

            @combo.reload.should_not be_active
            @combo.reload.response.creation_reason.should == "combo_yes"
          end
        end

        context "more yes than no" do
          before :each do
            @combo.no_count = 9
            @combo.yes_count = 7
          end

          it "should deactivate the combo and not create a response"  do
            @combo.should be_active

            ActiveRecord::Observer.with_observers(:combo_observer) { @combo.save! }

            @combo.reload.should_not be_active
            @combo.response.should be_nil
          end

        end
      end
    end
  end

  describe "couple_combo" do
    it "should email the owner of the photos when enough votes are collected" do
      ActiveRecord::Observer.with_observers(:combo_observer) do
        photo_one = Factory.create(:registered_photo, :gender => "m")
        photo_two = Factory.create(:registered_photo, :gender => "f")
        couple_combo = Combo.find_or_create_by_photo_ids(photo_one.id, photo_two.id)
        photo_one.update_attribute(:couple_combo, couple_combo)
        photo_two.update_attribute(:couple_combo, couple_combo)
        photo_one.confirm!
        photo_two.confirm!
        photo_one.approve!
        photo_two.approve!

        couple_combo.reload

        Delayed::Job.delete_all

        (Features.coupled_vote_count - 1).times { |i| Factory.create(:answer, :combo => couple_combo) }

        work_all_jobs
        ActionMailer::Base.deliveries.should be_empty

        Factory.create(:answer, :combo => couple_combo)

        work_all_jobs

        completed_notification = ActionMailer::Base.deliveries.only
        completed_notification.to_addrs.first.to_s.should include(photo_one.player.user.email)
        completed_notification.body.should =~ /Voting on your entry in to the Perfect Pair Challenge has completed!/
      end
    end

    it "should email any combo friends when enough votes are collected" do
      ActiveRecord::Observer.with_observers(:combo_observer) do
        photo_one = Factory.create(:registered_photo, :gender => "m")
        photo_two = Factory.create(:registered_photo, :gender => "f")

        couple_combo = Combo.find_or_create_by_photo_ids(photo_one.id, photo_two.id)
        photo_one.update_attribute(:couple_combo, couple_combo)
        photo_two.update_attribute(:couple_combo, couple_combo)
        photo_one.confirm!
        photo_two.confirm!
        photo_one.approve!
        photo_two.approve!

        other_photo_one = Factory.create(:registered_photo, :gender => "m")
        other_photo_two = Factory.create(:registered_photo, :gender => "f")
        other_couple_combo = Combo.find_or_create_by_photo_ids(other_photo_one.id, other_photo_two.id)
        other_photo_one.update_attribute(:couple_combo, other_couple_combo)
        other_photo_two.update_attribute(:couple_combo, other_couple_combo)
        other_photo_one.confirm!
        other_photo_two.confirm!
        other_photo_one.approve!
        other_photo_two.approve!

        CoupleFriend.find_or_create_by_combo_ids(couple_combo.id, other_couple_combo.id)

        couple_combo.reload

        Delayed::Job.delete_all

        (Features.coupled_vote_count - 1).times { |i| Factory.create(:answer, :combo => couple_combo) }

        work_all_jobs
        ActionMailer::Base.deliveries.should be_empty

        Factory.create(:answer, :combo => couple_combo)

        work_all_jobs

        completed_notification = ActionMailer::Base.deliveries.last
        completed_notification.to_addrs.first.to_s.should include(other_photo_one.player.user.email)
        completed_notification.body.should =~ /Voting on your friends' entry in to the Perfect Pair Challenge has completed!/
      end
    end
  end

end
