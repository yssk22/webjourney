module WebJourney  # :nodoc:
  module Component # :nodoc:
    module Task
      #
      # package task execution class
      #
      class Package
        module Path # :nodoc:
          DIRECTORIES_IN_COMPONENTS = {
            "configurations"   => "_config",
            "definitions"      => "_db/define",
            "migrations"       => "_db/migrate",
            "test"             => "_test",
            "unit_test"        => "_test/unit",
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

        module RegisterTask # :nodoc:
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

        module FileTask # :nodoc:
          # Copy all files existing deployed path to archived path
          def copy_to_archived
            copy_to(:deployed, :archived)
          end

          # Copy all files existing archived path to deployed path
          def copy_to_deployed
            copy_to(:archived, :deployed)
          end

          # Delete all files existing archived path.
          def cleanup_archived
            FileUtils.rm_r self.archived_base_directory
          end

          # Delete all files existing deployed path.
          def cleanup_deployed
            cleanup :deployed
          end


          private
          def copy_to(from, to)
            # directories
            %w(components static_files).each do |dir|
              dir_from = self.send "#{from}_#{dir}_directory"
              dir_to   = self.send "#{to}_#{dir}_directory"
              copy_directory_entry(dir_from,dir_to)
            end

            # po files
            self.send("#{from}_po_files").each do |file|
              lang = File.basename(File.dirname(file))
              dir = self.send("#{to}_po_files_directory", lang)
              FileUtils.mkdir_p dir unless FileTest.exist?(dir)
              FileUtils.copy_entry file, File.join(dir,"#{self.component_name}.po")
            end
          end

          def cleanup(type)
            # directories
            %w(components static_files).each do |dir|
              d   = self.send "#{type}_#{dir}_directory"
              FileUtils.rm_r d
            end
            # po files
            FileUtils.rm_r self.send("#{type}_po_files")
          end

          def copy_directory_entry(from, to)
            FileUtils.mkdir_p to unless FileTest.exist?(to)
            FileUtils.copy_entry from, to, true
          end
        end

        module MigrationTask
          def migrate(version = nil)
            current = current_version
            to = version || latest_version
            if current == to
              # nothing to do
            else
              raise "component record is not registered yet" unless migration_component_record
              if current < to # up
                apply_migrations(((current+1)..to).to_a, :up)
              else            # down
                apply_migrations(((to+1)..current).to_a.reverse, :down)
                migration_component_record.version = to
                migration_component_record.save!
              end
            end
          end

          def migration_component_record
            @migration_component ||= WjComponent.find_by_directory_name(self.component_name)
          end

          def current_version
            migration_component_record ? migration_component_record.version : 0
          end

          # Returns the list of migration number and migration name from deployed migrations directory
          def migrations
            @migrations ||= Dir[File.join(deployed_migrations_directory, "[0-9]*_*.rb")].map {  |f|
              v = f.scan(/([0-9])_([_a-z0-9]*).rb/).first
              [v.first.to_i, v.last]
            }.sort_by { |v| v.first }
            @migrations
          end

          def latest_version
            migrations.length > 0 ? migrations.last.first : 0
          end

          private
          def apply_migrations(versions, direction)
            versions.each do |v|
              # applies all migration files
              self.migrations.select {|m| m.first == v }. each do |migration|
                fullpath = File.join(deployed_migrations_directory, sprintf("%03d_%s.rb",migration.first, migration.last))
                load fullpath
                migration.last.camelize.constantize.migrate(direction)
                migration_component_record.version = migration.first
                migration_component_record.save!
              end
              # save the verison number if no files are applied
              if migration_component_record.version != v
                migration_component_record.version = v
                migration_component_record.save!
              end
            end
          end
        end

        #--
        # *********************************************************************
        #
        # main definition for Package class
        #
        # *********************************************************************
        #++

        include Path
        include FileTask
        include MigrationTask
        include RegisterTask

        attr_accessor :component_name
        #
        # initialize execution object for the specified <tt>component_name</tt>.
        #
        def initialize(component_name)
          raise ArgumentError.new("'component_name' shoud be _^[a-z][a-z0-9_]*$/") unless component_name =~ /^[a-z][a-z0-9_]*$/
          @component_name = component_name
          @output = $stdout
        end

        # Execute the installation.
        # If files have been already copied under <tt>RAILS_ROOT/components/{component_name}</tt> directory,
        # avoid to override deployed files to set <tt>deploy</tt> false.
        def install(deploy = false)
          copy_to_deployed if deploy
          register
          migrate
        end

        # Execute the uninstallation.
        # If files have been already copied under <tt>RAILS_ROOT/components/{component_name}</tt> directory,
        # avoid to remove deployed files to set <tt>deploy</tt> false.
        def uninstall(undeploy = false)
          migrate 0
          unregister
          cleanup_deployed if undeploy
        end

        # output process message.
        def puts(msg)
          @output.puts(msg) if @output.respond_to?(:puts)
        end

        # set the output such as STDOUT
        def set_output(output)
          @output = output
        end
      end
    end
  end
end
