namespace :db do

  def backup_command(env)
    require 'heroku'
    require 'heroku/command'
    require "heroku/command/base"
    require "heroku/pgutils"
    require "pgbackups/client"
    require "heroku/command/pgbackups"

    Heroku::Command::Pgbackups.new({}, :app => "thematchinggame-#{env}")
  end

  def client(command)
    PGBackups::Client.new(command.send(:config_vars)["PGBACKUPS_URL"])
  end

  desc "capture the production database"
  task :prod_capture do
    command = backup_command(:production)
    pgbackup_client = client(command)

    existing = pgbackup_client.get_transfers
    if existing.length >= 2
      puts "found 2 dumps, destroying the oldest"
      name = command.send(:backup_name, existing.first["to_url"])
      puts "Destroying backup #{name}"
      pgbackup_client.delete_backup(name)
    end

    command.capture
  end

  desc "capture production database and load locally"
  task :prod_reload do
    puts "recreating db"
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke

    puts "restoring data"
    %x{pg_restore -d matchinggame__dev db/pg.dump}
  end

  desc "capture production database and load locally"
  task :prod_pull => [:prod_capture] do
    new_dump_url = client(backup_command(:production)).get_latest_backup["public_url"]

    puts "downloading #{new_dump_url}"

    %x{wget "#{new_dump_url}" -O db/pg.dump}

    Rake::Task['db:prod_reload'].invoke
  end

  desc "staging clone"
  task :staging_clone do# => [:prod_capture] do
    from_url = client(backup_command(:production)).get_latest_backup["public_url"]
    from_name = "EXTERNAL_BACKUP (PRODUCTION)"

    staging_command = client(backup_command(:staging))
    to_url = backup_command(:staging).send(:config_vars)["SHARED_DATABASE_URL"]
    to_name = "SHARED_DATABASE_URL (STAGING)"

    puts "CLONING FROM #{from_url}\nTO #{to_url}"
    restore = backup_command(:staging).send(:transfer!, from_url, from_name, to_url, to_name)
    puts "MORE"
    restore = backup_command(:staging).send(:poll_transfer!, restore)
    abort(" !    An error occurred and your restore did not finish.") if restore["error_at"]

  end
end
