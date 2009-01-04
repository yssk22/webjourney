require 'digest/md5'
require 'rubygems'
require 'active_support'
require 'json'
module CouchResource
  module View
    def self.included(base)
      base.send(:extend,  ClassMethods)
      base.send(:include, InstanceMethods)
    end

    module ClassMethods
      # Get the design path specified by the <tt>design</tt> and <tt>view</tt> name.
      def design_path(design, query_options=nil)
        design_fullname = get_design_fullname(design)
        document_path("_design%2F#{design_fullname}", query_options)
      end

      # Get the view path specified by the <tt>design</tt> and <tt>view</tt> name.
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

      def get_design_fullname(design)
        "#{self.to_s}_#{design}"
      end

      def get_view_definition(design, view)
        design_documents = read_inheritable_attribute(:design_documents) || {}
        design_doc = design_documents[design.to_s]
        return nil unless design_doc
        return design_doc[:views][view]
      end

      # Define view on the server
      def view(design, views)
        # append prefix to design
        # Klass_design is a proper design document name
        design_fullname = get_design_fullname(design)

        design_document = {
          :_id       => "_design/#{design_fullname}",
          :language => "javascript",
          :views    => views
        }
        # Get the design document revision if exists.
        rev = connection.get(design_path(design))[:_rev] rescue nil
        design_document[:_rev] = rev if rev

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

      # define design document if it does not exist on the server.
      def define_design_document(design)
        design_document = read_inheritable_attribute(:design_documents)[design]
        if self.check_view_every_access
          path = design_path(design)
          logger.debug "CouchResource::Connection#get #{path}"
          current_doc = connection.get(path) rescue nil
          # already exists
          if current_doc
            logger.debug current_doc.to_json
            program = Digest::MD5.digest(design_document[:views].to_s)
            server  = Digest::MD5.digest(current_doc[:views].to_s)
            if program != server
              logger.debug "Design document should be updated."
              logger.debug "(server_md5, program_md5) = (#{server}, #{program})"
              logger.debug "(server_rev, program_rev) = (#{current_doc['_rev']}, #{design_document[:_rev]})"
              design_document[:_rev] = current_doc[:_rev]
              logger.debug "CouchResource::Connection#put #{path}"
              hash = connection.put(path, design_document.to_json)
              logger.debug hash.to_json
              design_document[:_rev] = hash[:rev]
            end
          else
            logger.debug nil.to_json
            design_document.delete(:_rev)
            logger.debug "CouchResource::Connection#put #{path}"
            logger.debug design_document.to_json
            hash = connection.put(path, design_document.to_json)
            logger.debug hash.to_json
            design_document[:_rev] = hash["rev"]
          end
        else
          if  design_document[:_rev].nil?
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
    end

    module InstanceMethods
    end
  end
end
