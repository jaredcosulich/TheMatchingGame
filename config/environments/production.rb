Match3::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local                   = false
  config.action_controller.perform_caching             = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = true #for heroku http://docs.heroku.com/rails3#serving-static-assets

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  STRIPE_API_KEY = "Cib1yda1uNu3i1IOIrJD0v9D8glc1J4L"
  STRIPE_PUBLIC_KEY = "AzA6xmQp2stmsuYbmxIQdbVwazfoI"

  FACEBOOK_APP_ID = "105077056190303"
  FACEBOOK_API_KEY = "40fa11243115860a75eb1d0a43fa8a9f"
  FACEBOOK_APP_SECRET = "3a6410b1dabd7344ea69471731d8894d"
  FACEBOOK_CANVAS_PAGE = "https://apps.facebook.com/thematchinggame/"

  config.logger    = Logger.new(STDOUT)
  config.log_level = :info

  config.before_initialize do
    ::PAPERCLIP_STORAGE_OPTIONS = S3_PAPERCLIP_STORAGE_OPTIONS

    ::SOCIAL_GOLD_OPTIONS[:server] = "api.jambool.com"
    ::SOCIAL_GOLD_OPTIONS[:virtual_currency_offer] = "bcny7v74rpn751ldr02ojc6p6"
    ::SOCIAL_GOLD_OPTIONS[:subscription_offer] = "4ox23sscfldgg34v941r5nSOF"
  end

end
