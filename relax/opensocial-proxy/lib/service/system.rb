require 'rubygems'

#
# OpenSocial system service
#
module Service
  class System
    # key valie pairs for available methods,
    # {service name => array of available methods}
    AVAILABLE_SERVICES = {
      :system => [:listMethods, :methodSignatures, :methodHelp],
      :people => [:get]
    }

    class << self
      #
      # Returns an array of supported methods.
      # See : http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/RPC-Protocol.html#rfc.section.9.9.1
      #
      def list_methods(params, req)
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
      def method_signatures(params, req)
        method_name = params["methodName"]
        # TODO must implement
        raise "must implement"
      end

      #
      # Returns a textual description of the operation.
      # See : http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/RPC-Protocol.html#rfc.section.9.9.3
      #
      def method_help(params, req)
        method_name = params["methodName"]
        # TODO may implement
        raise "may implement"
      end


      #
      # A proxy method of available methods. This method should be for the dispach routine.
      #
      def apply(service, method, params, request, token)
        k = service.to_sym
        m = method.to_sym
        if AVAILABLE_SERVICES.has_key?(k) &&
            AVAILABLE_SERVICES[k].include?(m)
          require File.join(File.dirname(__FILE__), service)
          klass_name = service[0,1].upcase + service[1..-1]
          klass = Service.const_get(klass_name)
          klass.method(m).call(params, request, token)
        else
          # TODO
          raise "not supported"
        end
      end
    end
  end
end
