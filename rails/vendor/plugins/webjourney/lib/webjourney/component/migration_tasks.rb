require File.join(File.dirname(__FILE__), "path")
module WebJourney
  module Component
    class Migration < ActiveRecord::Migration
    end

    module MigrationTasks
      def self.included(base)
        base.send  :include, InstanceMethods
        base.extend(ClassMethods)
      end

      module ClassMethods
      end

      module InstanceMethods
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
    end
  end
end
