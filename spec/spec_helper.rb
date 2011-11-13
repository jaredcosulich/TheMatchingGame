# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  ActiveRecord::Observer.disable_observers

  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.before(:each) do
    ActionMailer::Base.deliveries.clear
    Delayed::Job.delete_all
  end

end

def login_as(user)
  session["player_id"] = user.player.id
  controller.send(:cookies)["user_credentials"] = {:value => user.persistence_token, :expires => nil}
  user
end

def set_session_for_player(player)
  if player && player.user.present?
    login_as(player.user)
  else
    session["player_id"] = player.nil? ? nil : player.id
  end
  player
end

def sync_combo_scores
  ComboScore.find(:all, :include => :combo).each { |cs| cs.update_attributes(:yes_percent => cs.combo.yes_percent, :score => cs.combo.yes_percent)}
end

def verify_only_delayed_delivery(recipient_email, body_regex)
  job = Delayed::Job.all.only
  job.should be_present
  job.invoke_job
  verify_only_delivery(recipient_email, body_regex)
end

def verify_only_delivery(recipient_email, body_regex)
  message = ActionMailer::Base.deliveries.only
  message.to_addrs.first.to_s.should include(recipient_email)
  message.body.should =~ body_regex
end
