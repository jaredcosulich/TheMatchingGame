require 'spec_helper'

describe PredictionsProgress do
  describe "send_progress_report" do
    include Rails.application.routes.url_helpers

    it "should send reminders to users who have new prediction progress" do
      user = Factory.create(:user)
      user_no_progress = Factory.create(:user)
      combo_no_progress = Factory.create(:combo)
      combo_to_progress = Factory.create(:combo)

      game = user.player.games.create
      game.answers.create(:combo => combo_no_progress, :answer => "y", :player_id => game.player_id)
      answer_with_progress = game.answers.create(:combo => combo_to_progress, :answer => "y", :player_id => game.player_id)
      user_no_progress.player.games.create.answers.create(:combo => combo_no_progress, :answer => "y", :player_id => game.player_id)

      combo_to_progress.create_response(:photo_one_answer => "good", :photo_two_answer => "good")
      
      user.player.prediction_progress(1).should == [answer_with_progress]
      user_no_progress.player.prediction_progress(1).should be_empty

      ActionMailer::Base.deliveries.clear
      Delayed::Job.delete_all

      PredictionsProgress.send_progress_report(1)

      Delayed::Job.count.should == 1
      Delayed::Job.last.invoke_job

      ActionMailer::Base.deliveries.length.should == 1
      delivery = ActionMailer::Base.deliveries.last
      delivery.to_addrs.first.to_s.should include(user.email)

      Emailing.count.should == 1
      Link.count.should == 3
      Link.first.source.should == Emailing.last
      Link.first.path.should == answers_path
      Link.last.source.should == Emailing.last

      delivery.body.should include("/#{Link.last.id}/")
    end

  end
end
