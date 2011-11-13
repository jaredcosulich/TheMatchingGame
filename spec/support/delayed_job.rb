def work_all_jobs
  Delayed::Job.all.map do |job|
    job.invoke_job
    job.delete
  end
end
