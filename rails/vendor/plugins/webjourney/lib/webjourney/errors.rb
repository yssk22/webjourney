module WebJourney # :nodoc:
  # This module contains WebJourney Application Error classes which can be mapped to HTTP errors.
  module Errors
    # Unhandled error and represents the status 500.
    class ApplicationError < StandardError
      def initialize(msg=nil, *params)
        msg ||= "Uhhanlded exception occurred."
        super(sprintf(msg, params))
      end

      def http_status
        500
      end

      def to_xml
        xml = Builder::XmlMarkup.new
        xml.instruct! # <?xml version="1.0" encoding="UTF-8"?>
        xml.webjourney {
          xml.application_error {
            xml.status(self.http_status)
            xml.message(self.message)
          }
        }
      end

      def to_json
        to_hash.to_json
      end

      private
      def to_hash
        {
          :webjourney => {
            :application_error => {
              :status => self.http_status,
              :message => self.message
            }
          }
        }
      end
    end

    # Represents the status 400.
    class ClientRequestError < WebJourney::Errors::ApplicationError
      def initialize(msg=nil)
        super(msg || "invalid request.")
      end
      def http_status; 400; end
    end

    # Represents the status 401.
    class AuthenticationRequiredError < WebJourney::Errors::ApplicationError
      def initialize(msg=nil)
        super(msg || "access to request resource is not permitted because you have not logged in.(HTTP 401)")
      end
      def http_status; 401; end
    end

    # Represents the status 403.
    class ForbiddenError < WebJourney::Errors::ApplicationError
      def initialize(msg=nil)
        super(msg || "access to request resource is not permitted because you have no permission.(HTTP 403)")
      end

      def http_status; 403; end
    end

    # Represents the status 404.
    class NotFoundError < WebJourney::Errors::ApplicationError
      def initialize(msg=nil)
        super(msg || "request resource is not found on this server.(HTTP 404)")
      end
      def http_status; 404 end
    end

    # Represents the status 405.
    class MethodNotAllowedError < WebJourney::Errors::ApplicationError
      def initialize(msg=nil)
        super(msg || "method not allowed.")
      end
      def http_status; 405; end
    end

    # Represents the status 406.
    class MethodNotAcceptableError < WebJourney::Errors::ApplicationError
      def initialize(msg=nil)
        super(msg || "method not acceptable.")
      end
      def http_status; 406; end
    end

    # Represents the status 409.
    class ConflictError < WebJourney::Errors::ApplicationError
      def initialize(msg=nil)
        super(msg || "conflict data.")
      end
      def http_status; 409 end
    end
  end
end
