# Session Expiration
 ActionController::Base.session_options[:session_expires] = Time.now + 1.month

# logger for CouchDB Mapper class
CouchResource::Base.logger = RAILS_DEFAULT_LOGGER

