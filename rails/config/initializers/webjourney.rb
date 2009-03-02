# Session Expiration
 ActionController::Base.session_options[:session_expires] = Time.now + 1.month

# logger for CouchDB Mapper class
CouchResource::Base.logger = RAILS_DEFAULT_LOGGER

# Version description
module WebJourney
  Url       = "http://www.webjourney.org/project/"
  Version   = "0.6.1"
  Copyright = "2006-2009 webjourney.org"
end
