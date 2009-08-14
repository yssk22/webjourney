require 'rubygems'

#
# OpenSocial system service
#
module Service
  # An exception raised when the service is not suppored.
  class NotSupportedError < StandardError; end
  # An exception raised when the service should be supported but not yet.
  class LazyImplementationError < NotSupportedError; end

  class System
    # key valie pairs for available methods,
    # {service name => array of available methods}
    AVAILABLE_SERVICES = {
      :system     => [:listMethods, :methodSignatures, :methodHelp],
      :people     => [:get],
      :activities => [:get]
    }

    class << self
      #
      # Returns an array of supported methods.
      # See : http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/RPC-Protocol.html#rfc.section.9.9.1
      #
      def list_methods(params, token=nil, req=nil)
        AVAILABLE_SERVICES.map { |service, methods|
          methods.map { |m|
            "#{service}.#{m}"
          }
        }.flatten
      end

      #
      # Returns a method signature describing the types of the parameters
      # See : http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/RPC-Protocol.html#rfc.section.9.9.2
      #
      def method_signatures(params, token=nil, req=nil)
        method_name = params["methodName"]
        # TODO to be implemented
        raise LazyImplementationError.new
      end

      #
      # Returns a textual description of the operation.
      # See : http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/RPC-Protocol.html#rfc.section.9.9.3
      #
      def method_help(params, token=nil, req=nil)
        method_name = params["methodName"]
        # TODO to be implemented
        raise LazyImplementationError.new
      end


      #
      # A proxy method of available methods, used for the method delegation.
      #
      #   Service::System.apply("people", "get", params, req, token)
      #   #=> People.get(params, req, token)
      #
      #   Service::System.apply("system", "listMethods", params, req, token)
      #   #=> Service::System.list_methods(params, req. token)
      #
      #
      def apply(service, method, params, token, req)
        k = service.to_sym
        m = method.to_sym
        if AVAILABLE_SERVICES.has_key?(k) &&
            AVAILABLE_SERVICES[k].include?(m)
          require File.join(File.dirname(__FILE__), service)
          klass_name  = service[0,1].upcase + service[1..-1]
          method_name = get_method_signature(method)
          klass = Service.const_get(klass_name)
          klass.method(method_name).call(params, token, req)
        else
          raise NotSupportedError.new("Service(#{service}.#{method}) is not supported")
        end
      end

      private
      # Converting to ruby style method signature.
      # For example, a opensocial method 'fooMethod' is to be implemented as 'foo_method' in ruby.
      def get_method_signature(os_method_signature)
        os_method_signature.to_s.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z0-9])([A-Z])/,'\1_\2').downcase
      end
    end
  end
end
