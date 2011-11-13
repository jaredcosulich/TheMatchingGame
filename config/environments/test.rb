Match3::Application.configure do
  require 'pp'
  # Settings specified here will take precedence over those in config/environment.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr
  STRIPE_API_KEY = "IOxi6eXrVyMXu2ykYgngnVXAsYnzElG3"
  STRIPE_PUBLIC_KEY = "yNvkaRcCD7HxQFmMrFCSE4GPnZneb"

  FACEBOOK_APP_ID = "FAKE"
  FACEBOOK_API_KEY = "FAKE"
  FACEBOOK_APP_SECRET = "FAKE"
  FACEBOOK_CANVAS_PAGE = "http://apps.facebook.com/thematchinggame-test/"

  module ::Enumerable
    def only
      raise "expected exactly one item but there were #{size}" unless size == 1
      first
    end
  end

  config.before_initialize do
    ENV['PROCESS_IN_BACKGROUND'] = 'true'

    ::PAPERCLIP_STORAGE_OPTIONS = LOCAL_PAPERCLIP_STORAGE_OPTIONS
  end

end
