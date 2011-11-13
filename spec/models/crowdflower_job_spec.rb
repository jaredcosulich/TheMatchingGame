require 'spec_helper'

describe CrowdflowerJob do
  describe '.validate_signature' do
    before :each do
      @payload = "{\"job_id\":\"34313\",\"amount\":50,\"uid\":\"1\",\"job_title\":\"Find location specific webpage for hotel locations\",\"adjusted_amount\":10}"
    end

    it "should be true if the signature is correct" do
      CrowdflowerJob.should be_signature_valid(@payload, "7c5a4926611bf3ea6fdc46cb4c813fd1edf9c1cb")
    end

    it "should be false if the signature is not correct" do
      CrowdflowerJob.should_not be_signature_valid(@payload, "XXXX")
    end
  end

  describe ".pay_credits" do
    it "should assign credits when the job is completed" do
      user = Factory(:user)
      job = CrowdflowerJob.create(:user => user, :adjusted_amount => 20)
      user.reload.credits.should == 0
      job.update_attributes(:completed_at => Time.new)
      user.reload.credits.should == 20
    end
  end
end
