module WebJourney
  module Component
    # Resolve component path module.
    module Path
      def self.included(base)
        base.send  :include, InstanceMethods
        base.extend(ClassMethods)
      end

      module ClassMethods
      end

      # The methods to resolve specified component directroy path.
      # It is delegated to the task module (such as FileTask module) how to handle files in the specified component directory.
      module InstanceMethods
        DIRECTORIES_IN_COMPONENTS = {
          "configurations" => "_config",
          "definitions"    => "_db/define",
          "migrations"     => "_db/migrate",
          "test"      => "_test",
          "unit_test"      => "_test/unit",
          "functional_test"  => "_test/functional",
          "integration_test" => "_test/integration",
          "fixtures"         => "_test/fixtures"
        }

        DIRECTORIES_IN_PUBLIC = {
          "javascripts" => "javascripts",
          "stylesheets" => "stylesheets",
          "images"      => "images"
        }

        def archived_base_directory
          File.join(RAILS_ROOT, "archived", self.component_name)
        end

        def archived_components_directory
          File.join(archived_base_directory, "components")
        end

        def archived_migrations_directory
          File.join(archived_components_directory, "db/migrate")
        end

        def deployed_components_directory
          File.join(RAILS_ROOT, "components", self.component_name)
        end

        DIRECTORIES_IN_COMPONENTS.each do |key, path|
          module_eval <<-EOS
            def deployed_#{key}_directory
              File.join(deployed_components_directory, "#{path}")
            end
EOS
        end

        def deployed_po_files
          Dir.glob(File.join(RAILS_ROOT, "po/**/#{self.component_name}.po"))
        end

        def deployed_po_files_directory(lang = "en")
          File.join(RAILS_ROOT,  "po", lang)
        end

        def archived_po_files
          Dir.glob(File.join(archived_base_directory, "po/**/#{self.component_name}.po"))
        end

        def archived_po_files_directory(lang = "en")
          File.join(archived_base_directory,  "po", lang)
        end

        def deployed_static_files_directory
          File.join(RAILS_ROOT, "public/components", self.component_name)
        end

        def archived_static_files_directory
          File.join(archived_base_directory, "public")
        end
      end
    end
  end
end
