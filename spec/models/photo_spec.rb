require 'spec_helper'

describe Photo do

  describe "create" do
    it "should send an email to admins for approval" do
      Delayed::Job.count.should == 0
      ActionMailer::Base.deliveries.clear

      photo = Factory.create(:photo)

      photo.image_processing.should == true

      Delayed::Job.count.should == 2

      Delayed::Job.all.each { |job| job.invoke_job }

      ActionMailer::Base.deliveries.length.should == 1

      photo.reload.image_processing.should == false

    end

    it "should not allow you to create a photo if you already have the max number" do
      player = Factory.create(:registered_player)
      Features.max_photos_per_user.times { photo = Factory.create(:photo, :player => player); photo.confirm!; photo.approve! }
      player.reload.photos.length.should == Features.max_photos_per_user

      lambda {Factory.create(:photo, :player => player)}.should raise_error
    end

    it "should not allow you to create a photo if you are under 18" do
      player = Factory.create(:registered_player, :profile => Factory(:profile, :birthdate => 17.years.ago.to_date))

      lambda {Factory.create(:photo, :player => player)}.should raise_error
    end


  end

  describe "crop" do
    it "should use a delayed job to reprocess" do
      photo = Factory.create(:photo, :image => File.new("#{Rails.root}/spec/fixtures/bug.jpg"))

      photo.image.url(:normal).should == "/images/loading.gif"
      Delayed::Job.count.should == 2 #email, processing
      Delayed::Job.all.each { |job| job.invoke_job; job.destroy }
      photo.reload.image.url(:normal).should_not == "/images/loading.gif"


      photo.crop!(:x => 1, :y => 2, :w => 3, :h => 4)

      Delayed::Job.count.should == 1 #reprocessing
      photo.reload.image.url(:normal).should == "/images/loading.gif"

      Delayed::Job.all.each { |job| job.invoke_job; job.destroy }
      photo.reload.image.url(:normal).should_not == "/images/loading.gif"
      photo.crop.x.should == 1

      photo.crop!(:x => 2, :y => 2, :w => 3, :h => 4)

      Delayed::Job.count.should == 1 #reprocessing
      photo.reload.image.url(:normal).should == "/images/loading.gif"

      Delayed::Job.all.each { |job| job.invoke_job; job.destroy }
      photo.reload.image.url(:normal).should_not == "/images/loading.gif"
      photo.crop.x.should == 2
      Crop.count.should == 1
    end
  end


  describe "Combo generation" do
    it "should create a delayed job for combo creation when approved goes from false to true" do
      photo = Factory.create(:confirmed_photo)
      Delayed::Job.count.should == 2

      photo.approve!

      Delayed::Job.count.should == 3
    end

    it "should not create any delayed jobs when saved if already approved" do
      photo = Factory.create(:confirmed_photo)
      photo.approve!

      Delayed::Job.count.should == 3

      photo.save!

      Delayed::Job.count.should == 3
    end

    it "should not create any delayed jobs when saved if part of a couple combo" do
      photo_one = Factory.create(:confirmed_photo, :gender => "m")
      photo_two = Factory.create(:confirmed_photo, :gender => "f")
      couple_combo = Combo.find_or_create_by_photo_ids(photo_one.id, photo_two.id)
      photo_one.update_attribute(:couple_combo, couple_combo)
      photo_two.update_attribute(:couple_combo, couple_combo)

      Delayed::Job.count.should == 4
      
      photo_one.approve!
      photo_two.approve!

      Delayed::Job.count.should == 4
    end
  end

  describe "title" do
    before :each do
      @profile = Factory.create(:profile, :first_name => "Jared", :last_name => "Cosulich", :location_name => "Boston, MA")
      @photo = Factory.create(:photo, :player => @profile.player)
      @combo = Factory.create(:combo, :photo_one => @photo)
    end

    it "should be first name from location name" do
      @photo.title.should == "Jared C. (20 yrs) from Boston, MA"
    end

    it "should be first name if no location_name" do
      @profile.update_attribute(:location_name, "")
      @photo.title.should == "Jared C. (20 yrs)"
    end
  end

  describe "need_combos" do
    it "should not return photos that are part of a couple combo" do
      photo_one = Factory.create(:registered_photo, :gender => "m")
      photo_two = Factory.create(:registered_photo, :gender => "f", :player => photo_one.player)
      couple_combo = Combo.find_or_create_by_photo_ids(photo_one.id, photo_two.id)
      photo_one.update_attribute(:couple_combo, couple_combo)
      photo_two.update_attribute(:couple_combo, couple_combo)
      photo_one.confirm!
      photo_two.confirm!
      photo_one.approve!
      photo_two.approve!
      photo_one.player.user.update_attribute(:last_request_at, 10.minutes.ago)
      Photo.need_combos.should be_empty
    end
  end

  describe "combos needed" do
    it "should return 0 unless the photo is active" do
      photo = Factory(:photo)
      photo.combos_needed.should == 0
    end
  end

  describe "states" do
    before :each do
      @photo = Factory.create(:registered_photo)
    end

    it "should have an unconfirmed state" do
      @photo.should be_unconfirmed
      @photo.aasm_events_for_current_state.should == [:confirm]
    end

    it "should have an confirmed state" do
      @photo.confirm!
      @photo.should be_confirmed
      @photo.aasm_events_for_current_state.sort { |a, b| a.to_s <=> b.to_s }.should == [:approve, :pause, :reject, :remove]
    end

    it "should have an approved state" do
      @photo.confirm!
      @photo.approve!
      @photo.should be_approved
      @photo.aasm_events_for_current_state.sort { |a, b| a.to_s <=> b.to_s }.should == [:pause, :reject, :remove]


      Delayed::Job.last.invoke_job
      approved_notification = ActionMailer::Base.deliveries.only
      approved_notification.to_addrs.first.to_s.should include(@photo.player.user.email)
      approved_notification.body.should =~ /has been approved/
    end

    it "should have an rejected state" do
      @photo.confirm!
      Delayed::Job.delete_all
      @photo.reject!
      @photo.should be_rejected
      @photo.aasm_events_for_current_state.sort { |a, b| a.to_s <=> b.to_s }.should == [:approve, :remove, :resubmit]

      Delayed::Job.last.invoke_job
      rejection_notification = ActionMailer::Base.deliveries.only
      rejection_notification.to_addrs.first.to_s.should include(@photo.player.user.email)
      rejection_notification.body.should =~ /There is a problem with the photo you uploaded/
    end

    it "should have a paused state" do
      @photo.confirm!
      @photo.approve!
      @photo.pause!
      @photo.should be_paused
      @photo.aasm_events_for_current_state.sort { |a, b| a.to_s <=> b.to_s }.should == [:reject, :remove, :resume]
    end

    it "should have a paused_unapproved state" do
      @photo.confirm!
      @photo.pause!
      @photo.should be_paused_unapproved
      @photo.aasm_events_for_current_state.sort { |a, b| a.to_s <=> b.to_s }.should == [:remove, :resume]
    end

    it "should have a removed state" do
      @photo.confirm!
      @photo.remove!
      @photo.should be_removed
      @photo.aasm_events_for_current_state.sort { |a, b| a.to_s <=> b.to_s }.should == []
    end

    it "should not be resumable if there are too many approved photos" do
      player = @photo.player
      (Features.max_photos_per_user - player.photos.approved.count).times { photo = Factory.create(:photo, :player => player); photo.confirm!; photo.approve! }
      paused_photo = player.reload.photos.last
      paused_photo.pause!

      player.reload.photos.approved.count.should == Features.max_photos_per_user - 1

      photo = Factory.create(:photo, :player => player.reload)
      photo.confirm!
      photo.approve!

      player.reload.photos.approved.count.should == Features.max_photos_per_user

      lambda {paused_photo.resume!}.should raise_error

      photo.pause!

      lambda {paused_photo.resume!}.should_not raise_error
    end

  end

  describe "events" do
    describe "pause" do
      it "should deactivate all combos for the photo" do
        combo_one = Factory.create(:combo)
        photo = combo_one.photo_one
        combo_two = Factory.create(:combo, :photo_two => photo, :photo_one => Factory(:female_photo))

        combo_one.should be_active
        combo_two.should be_active

        photo.pause!

        combo_one.reload.should_not be_active
        combo_two.reload.should_not be_active
      end

      it "should not use the photo for new combos" do
        female_photo_to_pause = Factory.create(:combo).photos.detect{|p|p.gender == "f"}
        male_photo = Factory.create(:male_photo)
        female_photo = Factory.create(:female_photo)

        female_photo_to_pause.pause!

        Combinator.restock_one(male_photo)
        Combinator.restock_one(female_photo)

        female_photo_to_pause.combos.collect(&:active).should == [false]
        male_photo.combos.collect(&:active).should == [true]
        female_photo.combos.collect(&:active).should == [true, true]
      end
    end

    describe "resume (was approved)" do

      it "should regenerate combos for the photo" do
        photo = Factory.create(:combo).photo_one
        Factory.create(:male_photo)
        Factory.create(:female_photo)

        photo.combos.collect(& :active).should == [true]

        photo.pause!
        photo.combos.collect(& :active).should == [false]

        photo.resume!
        sync_combo_scores
        Delayed::Job.all.each { |j| j.invoke_job }
        photo.combos.sort.collect(& :active).should == [false, true]

      end
    end

    describe "resubmit" do
      it "should go to unconfirmed and clear the rejected reason" do
        photo = Factory.create(:registered_photo)
        photo.confirm!
        photo.reject!
        photo.update_attribute(:rejected_reason, "bad")

        photo.resubmit!
        photo.reload.should be_unconfirmed
        photo.reload.rejected_reason.should be_blank

        photo.aasm_events_for_current_state.sort { |a, b| a.to_s <=> b.to_s }.should == [:confirm]
      end

    end
  end

  describe "notify_unconfirmed" do
    it "should notify people who have a photo that is unconfirmed and more than one day old, but less than 2 days old" do
      Factory(:registered_photo, :created_at => 3.days.ago)
      recent_photo = Factory(:registered_photo, :created_at => 36.hours.ago)
      Factory(:registered_photo, :created_at => 1.hour.ago)

      Delayed::Job.delete_all

      Photo.notify_unconfirmed
      verify_only_delayed_delivery(recent_photo.player.user.email, /unconfirmed photo/)
    end
  end
end
