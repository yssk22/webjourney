# local fix for map.connect
# in the case of the different :namespace and :path_prefix
module ActionController
  module Routing
    class RouteBuilder #:nodoc:
      alias :divide_route_options_org :divide_route_options
      #
      # This method is originated in the Rails (action_controller/routing.rb)
      # ActionController::Routing::RouteBuilder#divide_route_options(segments, options)
      #
      def divide_route_options(segments, options)
        options = options.dup
        if options[:namespace]
          options[:controller] = "#{options[:namespace]}#{options[:controller]}"
          options.delete(:path_prefix)
          options.delete(:name_prefix)
          options.delete(:namespace)
        end
        divide_route_options_org(segments, options)
      end
    end
  end
end
