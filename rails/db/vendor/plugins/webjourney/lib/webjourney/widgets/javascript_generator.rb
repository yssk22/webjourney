module WebJourney
  module Widgets
    module JavaScriptObject
      class Base
        def initialize(object)
          @object = object
        end

        def js_obj
          "Page.getWidgetInstanceById('#{@object.dom_id}')"
        end
        alias :js_object :js_obj

        # hook all the undefined method to convert to javascript string.
        # To call ruby method (such js_obj), use __send__ method.
        def method_missing(method, *args)
          js_object = self.js_object
          js_method = method.to_s.camelize(:lower)
          js_args   = args.map { |a| a.to_json }.join(",")
          return "#{js_object}.#{js_method}(#{js_args})"
        end
        # enable load method to pass js object
        undef load
      end

      # mapping AR / WjComponentPage object to WjComponentPageWidget object in javascript.
      class JsWjComponentPageWidget < Base
      end

      # mapping AR / WjPageWidgetInstance object to WjPageWidgetInstance object in javascript.
      class JsWjPageWidgetInstance < Base
      end
    end
  end
end
