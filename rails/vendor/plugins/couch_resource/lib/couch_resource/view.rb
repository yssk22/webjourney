require 'digest/md5'
require 'rubygems'
require 'active_support'
require 'json'

#
# == Synchronization of design documents
#
# Synchronization mechanism of design documents is controlled by <tt>check_design_revision_every_time</tt>.
# The value is true, the finder methods of views always check the revision of the design document.
# When false, the finder methods only check at first time.
#
module CouchResource
  module View
    def self.included(base)
      base.send(:extend,  ClassMethods)
      # base.send(:include, InstanceMethods)
    end

    module ClassMethods
      # Returns the design path specified by the <tt>design</tt> and <tt>view</tt> name.
      def design_path(design, query_options=nil)
        design_fullname = get_design_fullname(design)
        # document_path("_design%2F#{design_fullname}", query_options)
        document_path("_design/#{design_fullname}", query_options)
      end

      # returns the view path specified by the <tt>design</tt> and <tt>view</tt> name.
      def view_path(design, view, query_options=nil)
        design_fullname = get_design_fullname(design)
        view_options = {}
        if query_options
          # convert query args to json value
          [:key, :startkey, :endkey].each do |arg|
            view_options[arg] = query_options[arg].to_json if query_options.has_key?(arg)
          end

          # do not care
          [:include_docs, :update, :descending, :group, :startkey_docid, :endkey_docid, :count, :skip, :group_level].each do |arg|
            view_options[arg] = query_options[arg] if query_options.has_key?(arg)
          end
        end
        document_path(File.join("_view", design_fullname, view.to_s), view_options)
      end

      # Returns the full name of design document.
      def get_design_fullname(design)
        "#{self.to_s}_#{design}"
      end

      # Returns the view definition hash which contains :map key and :reduce key (optional).
      def get_view_definition(design, view)
        design_documents = read_inheritable_attribute(:design_documents) || {}
        design_doc = design_documents[design.to_s]
        return nil unless design_doc
        return design_doc[:views][view]
      end


      # Define view on the server  access method for this class.
      #
      # for example, the following code defines a design_document at _design/SomeDocument_my_design ::
      #
      #   class SomeDocument
      #     view :my_design, :sample_view => {
      #       :map    => include_js("path/to/map.js")
      #       :reduce => include_js("path/to/reduce.js")
      #     }
      #   end
      #
      # The design document include one view whose name is 'sample_view'.
      # And following 4 methods will be available in SomeDocument class.
      #
      #   SomeDocument.find_my_design_sample_view()
      #   SomeDocument.find_my_design_sample_view_first()
      #   SomeDocument.find_my_design_sample_view_last()
      #   SomeDocument.find_my_design_sample_view_all()
      #
      # The design document actually stored on the server at the first time when the above methods are invoked.
      #
      def view(design, views)
        # append prefix to design
        # Klass_design is a proper design document name
        design_fullname = get_design_fullname(design)

        design_document = {
          :_id       => "_design/#{design_fullname}",
          :language => "javascript",
          :views    => views
        }
        # Get the design document revision if already exists.
        logger.debug "Design Doc: get the existance revision."
        rev = connection.get(design_path(design))[:_rev] rescue nil
        design_document[:_rev] = rev if rev
        logger.debug "Design Doc: revision: #{rev || 'not found'}"

        # Update inheritable attribute for design_documents
        design_documents = read_inheritable_attribute(:design_documents) || {}
        design_documents[design.to_s] = design_document
        write_inheritable_attribute(:design_documents, design_documents)

        # define query method for each views
        # find_{design}_{view}(*args)   -- key is one of :all, :first, :last
        # find_{design}_{view}_all(options)
        # find_{design}_{view}_first(options)
        # find_{design}_{view}_last(options)
        views.each do |viewname, functions|
          define_view_method(design, viewname)
        end
      end

      # Returns the string of the javascript file stored in the <tt>path</tt>
      # The <tt>path</tt> is the relative path, root of which is the directory of the caller.
      # The <tt>root</tt> can be also specified in the second argument.
      def include_js(path, root = nil)
        # set root the current directory of the caller.
        if root.nil?
          from = caller.first
          if from =~ /^(.+?):(\d+)/
            root = File.dirname($1)
          else
            root = RAILS_ROOT
          end
        end
        fullpath = File.join(root, path)
        ERB.new(File.read(fullpath)).result(binding)
      end

      def define_view_method(design, view)
        method = <<-EOS
        def self.find_#{design}_#{view}(*args)
          options = args.extract_options!
          define_design_document("#{design.to_s}")
          case args.first
          when :first
            find_#{design}_#{view}_first(options)
          when :last
            find_#{design}_#{view}_last(options)
          else
            find_#{design}_#{view}_all(options)
          end
        end
EOS
        class_eval(method, __FILE__, __LINE__)

        [:all, :first, :last].each do |key|
          method = <<-EOS
          def self.find_#{design}_#{view}_#{key}(options = {})
            define_design_document("#{design.to_s}")
            find_#{key}("#{design}", :#{view}, options)
          end
EOS
          class_eval(method, __FILE__, __LINE__)
        end
      end

      def get_design_document_from_server(design)
        path = design_path(design)
        logger.debug "CouchResource::Connection#get #{path}"
        connection.get(path) rescue nil
      end

      # Define design document if it does not exist on the server.
      def define_design_document(design)
        path = design_path(design)
        design_document         = read_inheritable_attribute(:design_documents)[design]
        design_revision_checked = read_inheritable_attribute(:design_revision_checked) || false
        logger.debug "Design Document Check"
        logger.debug "  check_design_revision_every_time = #{check_design_revision_every_time}"
        logger.debug "  design_revision_checked          = #{design_revision_checked}"
        #if self.check_view_every_access
        if self.check_design_revision_every_time || !design_revision_checked
          current_doc = get_design_document_from_server(design)
          # already exists
          if current_doc
            logger.debug "Design document is found and updates are being checked."
            logger.debug current_doc.to_json
            if match_views?(design_document[:views], current_doc[:views])
              logger.debug "Design document(#{path}) is the latest."
            else
              logger.debug "Design document(#{path}) is not the latest, should be updated."
              design_document[:_rev] = current_doc[:_rev]
              logger.debug "CouchResource::Connection#put #{path}"
              hash = connection.put(path, design_document.to_json)
              logger.debug hash.to_json
              design_document[:_rev] = hash[:rev]
            end
          else
            logger.debug "Design document not found so to put."
            design_document.delete(:_rev)
            logger.debug "CouchResource::Connection#put #{path}"
            logger.debug design_document.to_json
            hash = connection.put(path, design_document.to_json)
            logger.debug hash.to_json
            design_document[:_rev] = hash["rev"]
          end
          design_revision_checked = true
        else
          if design_document[:_rev].nil?
            begin
              hash = connection.put(design_path(design), design_document.to_json)
              design_document[:_rev] = hash[:rev]
            rescue CouchResource::PreconditionFailed
              # through the error.
              design_document[:_rev] = connection.get(design_path(design))[:_rev]
            end
          end
        end
      end

      private
      def match_views?(views1, views2)
        # {
        #   :view_name => {:map => ..., :reduce => ...},
        #   ...
        # }
        views1.each do |key, mapred1|
          return false unless views2.has_key?(key)
          mapred2 = views2[key]
          redhex = [Digest::MD5.hexdigest(mapred1[:reduce].to_s), Digest::MD5.hexdigest(mapred2[:reduce].to_s)]
          return false  unless Digest::MD5.hexdigest(mapred1[:map].to_s) == Digest::MD5.hexdigest(mapred2[:map].to_s)
          return false  unless Digest::MD5.hexdigest(mapred1[:reduce].to_s) == Digest::MD5.hexdigest(mapred2[:reduce].to_s)
        end
        true
      end
    end
  end
end
