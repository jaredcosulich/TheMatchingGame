Match3::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  STRIPE_API_KEY = "IOxi6eXrVyMXu2ykYgngnVXAsYnzElG3"
  STRIPE_PUBLIC_KEY = "yNvkaRcCD7HxQFmMrFCSE4GPnZneb"

  FACEBOOK_APP_ID = "104015342967729"
  FACEBOOK_API_KEY = "2e6578b32a204632a90b5a5de1a42418"
  FACEBOOK_APP_SECRET = "1607c57472adf6bf0e75fba3615cc759"
  FACEBOOK_CANVAS_PAGE = "http://apps.facebook.com/thematchinggame-dev/"

  config.action_mailer.perform_deliveries = ENV['SEND_MAIL'].present?

  require 'pp'
  require 'benchmark'

#  ENV['CLOUDANT_URL'] = 'http://localhost:5984'

  config.before_initialize do
    ::PAPERCLIP_STORAGE_OPTIONS = S3_PAPERCLIP_STORAGE_OPTIONS

    ::SOCIAL_GOLD_OPTIONS[:server] = "api.sandbox.jambool.com"
    ::SOCIAL_GOLD_OPTIONS[:virtual_currency_offer] = "kyog2k1ctd4kmc0yeer8a5y22"
    ::SOCIAL_GOLD_OPTIONS[:subscription_offer] = "074kh85tyvbw5k48kue8a7SOF"

    class ::ActiveRecord::LogSubscriber
      include QueryTrace
    end
  end

#  config.middleware.use "Rack::Bug",
#                        :password => 'thud',
#                        :secret_key => "f90427bd769bcf9b050d2b0a547a47dbe9b6afd3364525c3df503289039433b03ef1da1b87c1c39e93d8b2f0dbab73e2d7b3384ad9721b85b2faf8e4ae263ec9"

end
