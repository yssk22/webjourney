require 'fileutils'
require File.join(File.dirname(__FILE__), "path")
module WebJourney
  module Component
    module FileTasks
      def self.included(base)
        base.send  :include, Path
        base.send  :include, InstanceMethods
        base.extend(ClassMethods)
      end

      module ClassMethods
      end

      module InstanceMethods
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
    end
  end
end
