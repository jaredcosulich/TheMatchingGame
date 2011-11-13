# Be sure to restart your server when you modify this file.

Match3::Application.config.session_store :cookie_store, :key => '_match3_session', :expire_after => 90.days

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# Match3::Application.config.session_store :active_record_store
