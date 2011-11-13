require 'spec_helper'

describe CrowdflowerJobsController do

  describe "#initiate" do

    it "should create a Job" do
      user = Factory(:user)
      payload = "{\"job_id\":\"34313\",\"amount\":50,\"uid\":\"#{user.id.to_obfuscated}\",\"job_title\":\"Find location specific webpage for hotel locations\",\"adjusted_amount\":10}"
      CrowdflowerJob.should_receive(:signature_valid?).with(payload, 'signature').and_return(true)

      post :initiate, :payload =>  payload, :signature => "signature"

      response.should be_success
      crowdflower_job = CrowdflowerJob.all.only
      response.body.should == crowdflower_job.conversion_id

      crowdflower_job.job_id.should == 34313
      crowdflower_job.job_title.should == 'Find location specific webpage for hotel locations'
      crowdflower_job.amount.should == 50
      crowdflower_job.adjusted_amount.should == 10
      crowdflower_job.initiate_payload.should == payload
      crowdflower_job.completed_at.should be_nil
      crowdflower_job.user.should == user
    end

    it "should verify signature" do
      user = Factory(:user)
      payload = "{\"job_id\":\"34313\",\"amount\":50,\"uid\":\"#{user.id.to_obfuscated}\",\"job_title\":\"Find location specific webpage for hotel locations\",\"adjusted_amount\":10}"
      CrowdflowerJob.should_receive(:signature_valid?).with(payload, 'signature').and_return(false)

      post :initiate, :payload =>  payload, :signature => "signature"

      response.should be_forbidden

      CrowdflowerJob.count.should == 0
    end
  end

  describe "#complete" do
    it "should find the job by conversion_id and mark it as completed" do
      user = Factory(:user)
      user.credits.should == 0
      crowdflower_job = CrowdflowerJob.create!(:user => user, :adjusted_amount => 10)

      payload = "{\"job_id\":\"34313\",\"amount\":50,\"conversion_id\":\"#{crowdflower_job.conversion_id}\",\"job_title\":\"Find location specific webpage for hotel locations\",\"adjusted_amount\":10}"
      CrowdflowerJob.should_receive(:signature_valid?).with(payload, 'signature').and_return(true)

      post :complete, :payload =>  payload, :signature => "signature"

      response.should be_success
      response.body.should == "OK"

      crowdflower_job.reload
      crowdflower_job.completed_at.should_not be_nil
      crowdflower_job.complete_payload.should == payload

      user.reload.credits.should == 10
    end

    it "should verify signature" do
      crowdflower_job = CrowdflowerJob.create!(:user => Factory(:user))

      payload = "{\"job_id\":\"34313\",\"amount\":50,\"conversion_id\":\"#{crowdflower_job.conversion_id}\",\"job_title\":\"Find location specific webpage for hotel locations\",\"adjusted_amount\":10}"
      CrowdflowerJob.should_receive(:signature_valid?).with(payload, 'signature').and_return(false)

      post :complete, :payload =>  payload, :signature => "signature"

      response.should be_forbidden

      crowdflower_job.reload
      crowdflower_job.completed_at.should be_nil
    end
  end
end
