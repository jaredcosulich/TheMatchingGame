require 'spec_helper'

describe ResponseReminder do
  describe "send_reminders" do
    include Rails.application.routes.url_helpers

    it "should send reminders to all users with emails who have matches that have not already been emailed about that match" do
      ActiveRecord::Observer.with_observers(:combo_observer) do
        Link.count.should == 0
        no_matches = Factory.create(:registered_photo)
        no_matches.confirm!
        no_matches.approve!
        with_matches_but_emailed = Factory.create(:registered_photo)
        with_matches_but_emailed.confirm!
        with_matches_but_emailed.approve!
        emailed_combo = Factory.create(:combo, :photo_one => with_matches_but_emailed, :yes_count => 10)
        emailed_combo.update_attribute(:photo_one_emailed_at, Time.new)

        with_matches = Factory.create(:registered_photo)
        with_matches.confirm!
        with_matches.approve!
        combo = Factory.create(:combo, :photo_one => with_matches, :yes_count => 10)
        combo.save!

        ActionMailer::Base.deliveries.clear
        Delayed::Job.delete_all
        Link.count.should == 0
        combo.photo_one_emailed_at.should be_nil

        Response.reveal_some
        Response.where("revealed_at > now()").each { |r| r.update_attribute(:revealed_at, 1.hour.ago)}
        ResponseReminder.send_reminders
        work_all_jobs

        ActionMailer::Base.deliveries.length.should == 3
        delivery = ActionMailer::Base.deliveries.detect { |d| d.to_addrs.first.to_s == with_matches.player.user.email }
        delivery.to_addrs.first.to_s.should include(with_matches.player.user.email)

        combo.reload
        combo.photo_one_emailed_at.should_not be_nil

        Emailing.count.should == 3
        Link.count.should == 12
        delivery_link = Link.all.detect { |l| l.path == photos_path && l.source.user_id == with_matches.player.user.id }
        delivery_link.should_not be_nil
        delivery.body.should include("/#{delivery_link.id}/")
      end
    end

    it "should not include a photo unless that photo has matches (for people with multiple photos)" do
      ActiveRecord::Observer.with_observers(:combo_observer) do
        Link.count.should == 0
        with_matches = Factory.create(:registered_photo)
        with_matches.confirm!
        with_matches.approve!
        with_matches.update_attribute(:image_processing, false)
        combo = Factory.create(:combo, :photo_one => with_matches, :yes_count => 10)

        no_matches_but_same_photo = Factory.create(:registered_photo, :player => with_matches.player)
        no_matches_but_same_photo.confirm!
        no_matches_but_same_photo.approve!
        no_matches_but_same_photo.update_attribute(:image_processing, false)


        ActionMailer::Base.deliveries.clear
        Delayed::Job.delete_all

        combo.save!
        Response.reveal_some
        Response.where("revealed_at > now()").each { |r| r.update_attribute(:revealed_at, 1.hour.ago)}
        sync_combo_scores

        ResponseReminder.send_reminders
        work_all_jobs

        ActionMailer::Base.deliveries.length.should == 2
        delivery_body = ActionMailer::Base.deliveries.last.body
        delivery_body.should include(with_matches.image.url(:preview))
        delivery_body.should_not include(no_matches_but_same_photo.image.url(:preview))
      end
    end
  end
end
