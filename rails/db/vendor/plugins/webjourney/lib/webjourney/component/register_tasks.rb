require 'yaml'
require File.join(File.dirname(__FILE__), "path")
module WebJourney
  module Component
    module RegisterTasks
      def self.included(base)
        base.send  :include, Path
        base.send  :include, InstanceMethods
        base.extend(ClassMethods)
      end

      module ClassMethods
      end

      module InstanceMethods
        # Register component records into database following to
        #   - _db/define/wj_component.yml        (required)
        #   - _db/define/wj_component_pages.yml  (optional)
        #   - _db/define/wj_widgets.yml          (optional)
        # files
        def register
          WjComponent.transaction do
            definitions = definitions_from_deployed
            component_record = register_component_record(definitions[:wj_component])
            register_component_pages_record(component_record, definitions[:wj_component_pages])
            register_widgets_record(component_record, definitions[:wj_widgets])
          end
        end

        # Unregister component records
        def unregister
          WjComponent.find_by_directory_name(self.component_name).destroy
        end

        # Returns the properties hash defined in yaml files (from deployed directory).
        # The hash structure is :
        #   {
        #      :wj_component          => {..}
        #      :wj_component_pages    => [{..}, {..}, ...]
        #      :wj_widgets_           => [{..}, {..}, ...]
        #   }
        # Each of hashes ({..}) has the keys and values applied to WjComponent, WjComponentPage, WjWidget models.
        # (Thus the keys are the same as database column names)
        def definitions_from_deployed
          {
            :wj_component       => read_yaml_file(:deployed, "wj_component.yml") || {},
            :wj_component_pages => read_yaml_file(:deployed, "wj_component_pages.yml", true) || [],
            :wj_widgets         => read_yaml_file(:deployed, "wj_widgets.yml", true)         || []
          }
        end

        # Returns the properties hash defined in yaml files (from archiveded directory).
        def definitions_from_archived
          {
            :wj_component       => read_yaml_file(:archived, "wj_component.yml")       || {},
            :wj_component_pages => read_yaml_file(:archived, "wj_component_pages.yml") || [],
            :wj_widgets         => read_yaml_file(:archived, "wj_widgets.yml")         || []
          }
        end

        private
        def register_component_record(definition)
          component_record = WjComponent.find_by_directory_name(self.component_name)
          component_record ||= WjComponent.new(:directory_name => self.component_name)
          install_or_update = component_record.new_record? ? "Install" : "Update"
          apply_properties(component_record, {
                             :url => "",
                             :display_name => self.component_name.titleize,
                             :description => "",
                             :license => "",
                             :author => ""
                           }, definition)
          component_record.save!
          puts <<-EOS
[#{install_or_update}][Component] #{component_record.directory_name}
  Display Name : #{component_record.display_name}
  Author       : #{component_record.author}
  URL          : #{component_record.url}
  License      : #{component_record.license}
EOS
          component_record
        end

        def register_component_pages_record(component_record, definitions)
          order = 1
          definitions.each do |d|
            d.each do |controller, properties|
              page_record = component_record.wj_component_pages.find_by_controller_name(controller)
              page_record ||= WjComponentPage.new(:wj_component_id => component_record.id,
                                                  :controller_name => controller)
              install_or_update = page_record.new_record? ? "Install" : "Update"
              apply_properties(page_record, {
                                 :display_name => controller.titleize
                               }, properties)
              page_record.menu_order = order
              page_record.save!
              puts <<-EOS
[#{install_or_update}][Page] #{page_record.controller}
  Display Name : #{page_record.display_name}
EOS
            end # d.each
            order = order + 1
          end # definitions.each
        end

        def register_widgets_record(component_record, definitions)
          order = 1
          definitions.each do |d|
            d.each do |controller, properties|
              widget_record = component_record.wj_widgets.find_by_controller_name(controller)
              widget_record ||= WjWidget.new(:wj_component_id => component_record.id,
                                             :controller_name => controller)
              install_or_update = widget_record.new_record? ? "Install" : "Update"
              apply_properties(widget_record, {
                                 :display_name => controller.titleize,
                                 :with_boxing  => true,
                                 :parameters   => nil,
                               }, properties)
              widget_record.save!

              puts <<-EOS
[#{install_or_update}][Widget] #{widget_record.controller}
  Display Name : #{widget_record.display_name}
EOS

            end # d.each
            order = order + 1
          end # definitions.each
        end

        def read_yaml_file(from, filepath, ignore_file_no_existance=true)
          fullpath = File.join(self.send("#{from.to_s}_definitions_directory"), filepath)
          if ignore_file_no_existance
            File.exist?(fullpath) ? YAML.load_file(fullpath) : nil
          else
            YAML.load_file(fullpath)
          end
        end

        def apply_properties(record, defaults, properties)
          defaults.each do |k, v|
            key = k.to_s
            properties[key] = v unless properties.has_key?(key)
            record[key] = properties[key]
          end
        end
      end
    end
  end
end
