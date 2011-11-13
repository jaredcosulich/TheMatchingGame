namespace :deploy do


  def heroku(command)
    system_or_exit("heroku #{command} --app thematchinggame-#{HEROKU_APP}")
  end

  def deploy
    heroku "maintenance:on"
    system_or_exit "git push #{HEROKU_APP}"
    heroku "rake db:migrate"
    heroku "restart"
  ensure
    heroku "maintenance:off"
  end

  desc "deploy to staging"
  task :staging do
    HEROKU_APP = "staging"
    deploy
  end

  desc "deploy to production"
  task :production do
    HEROKU_APP = "production"
    deploy
  end

  desc "pull db from production"
  task :db_pull do
    system_or_exit("rake db:drop")
    system_or_exit("rake db:create")
    HEROKU_APP = "production"
    heroku "db:pull"
  end

  desc "clone staging db from production"
  task :db_clone => [:db_pull] do
    HEROKU_APP = "staging"
    heroku "db:reset"
    heroku "db:push"
  end

end

def system_or_exit(command, message = nil)
  puts message, "" if message
  puts "*** #{command}"
  system(command) or raise("#{command} failed")
end
