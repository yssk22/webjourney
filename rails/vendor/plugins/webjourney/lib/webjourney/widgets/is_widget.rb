require File.join(File.dirname(__FILE__), "javascript_generator")

module WebJourney
  module Widgets
    module IsWidget
      def self.append_features(base)
        super
        base.extend(ClassMethods)
      end

      module ClassMethods
        # is_widget DSL.
        # It is the signature of the controller that implies the widget.
        # The request is received by the url /widgets/[instance_id]/[layout]/[component]/[page]/[action]
        #
        # <tt>options</tt> are
        # - :parameters
        #   the default parameter hash used for widget instance
        # - :use_iframe
        #   when this option is set true, the widget instance is initialized by iframe.
        #   The default is false and the widget instance is initialized by ajax.
        def is_widget(options = {})
          self.send :include, WebJourney::Widgets::IsWidget::InstanceMethods
          hide_action :instance, :js_object
          self.send :helper_method, :instance
          self.send :helper_method, :js_instance
          self.send :helper_method, :edit_form_enable?
          self.send :helper_method, :edit_button_enable?
          self.send :helper_method, :delete_button_enable?
          self.send :helper, WebJourney::Widgets::WidgetHelper

          self.send :before_filter, :is_widget_before_filter
          self.send :after_filter , :is_widget_after_filter
          self.send :layout, :select_layout
          # In Rails 2.0, :template_root= method is unavailable
          # self.send :template_root=, File.join(RAILS_ROOT, "components", self.controller_path, "../..")
          self.send :view_paths=, [File.join(RAILS_ROOT, "app/views"), File.join(RAILS_ROOT, "components", self.controller_path, "../..")]
          self.send :init_gettext, self.to_s.underscore.split("/").first

          # process with option
          write_inheritable_attribute :parameters, options[:parameters] || {}
          write_inheritable_attribute :initialize, options[:initialize] || "ajax"
          write_inheritable_attribute :is_widget, true
        end
      end

      module InstanceMethods

        def instance
          @instance
        end

        def js_instance
          @js_object.js_obj
        end

#        def js_object
#          @js_object
#        end

        def edit_form_enable?
          params[:action] == "edit"
        end

        def edit_button_enable?
          @edit_button_enable
        end

        def delete_button_enable?
          @delete_button_enable
        end

        protected
        def select_layout
          if instance.wj_widget.use_iframe
            if params[:action] == "show"
              case params[:_layout]
              when "iframe"
                "widget_iframe_content"
              else
                "widget_iframe_link"
              end
            end
          end
        end

        def is_widget_before_filter
          # select the widget instance
          component, page = params[:controller].split('/')
          # TODO Widget Instance polymophism?? (WjMasterPageWidgetInstance ???)
          @instance = WjPageWidgetInstance.find(params[:instance_id])
          raise WebJourney::NotFoundError("Widget instance is not found.") unless @instance
          # verify controller name
          raise WebJourney::ClientRequestError.new("Invalid controller name") unless @instance.wj_widget.controller == params[:controller]

          # OK
          @js_object = JavaScriptObject::JsWjPageWidgetInstance.new(@instance)

          @edit_button_enable = @instance.wj_page.can_be_edited_by?(current_user)
          # TODO check the page is in edit mode or not.
          @delete_button_enable = @edit_button_enable

          if params[:action] == "update"
            @instance.title = params[:instance][:title]
          end

          # default parameter set if @instance.parameters is nil
          @instance.parameters ||= {}
          init_instance_parameters
        end

        def is_widget_after_filter
          # reserved filter
        end

        def init_instance_parameters
          default = self.class.read_inheritable_attribute(:parameters)
          default.each do |k,v|
            unless @instance.parameters.has_key?(k)
            @instance.parameters[k] = if v.kind_of?(Symbol)
                                        self.send v
                                      elsif v.kind_of?(Proc)
                                        v.call
                                      else
                                        v
                                      end
            end
          end
        end
      end
    end
  end
end

ActionController::Base::send :include, WebJourney::Widgets::IsWidget
