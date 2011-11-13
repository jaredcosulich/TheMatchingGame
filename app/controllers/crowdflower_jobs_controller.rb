class CrowdflowerJobsController < ApplicationController
  before_filter :verify_signature
  def initiate
    payload = JSON.parse(params[:payload])
    user = User.find(Integer.unobfuscate(payload.delete("uid")))
    job = CrowdflowerJob.create(payload.merge(:user => user, :initiate_payload => params[:payload]))
    render :text => job.conversion_id
  end

  def complete
    payload = JSON.parse(params[:payload])
    job = CrowdflowerJob.find_by_conversion_id(payload["conversion_id"])
    job.update_attributes(:completed_at => Time.now, :complete_payload => params[:payload])
    render :text => "OK"
  end

  protected

  def verify_signature
    if CrowdflowerJob.signature_valid?(params[:payload], params[:signature])
      true
    else
      head 403 and return false
    end
  end
end
