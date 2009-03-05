require 'rubygems'
require 'json'
require File.join(File.dirname(__FILE__), 'error')
require File.join(File.dirname(__FILE__), 'connection')

module CouchResource
  class Base
    cattr_accessor :logger, :instance_writer => false
    cattr_accessor :check_design_revision_every_time, :instance_writer => false

    class << self
      # Get the URI of the CouchDB database to map for this class
      def database
        if defined?(@database)
          @database
        elsif superclass != Object && superclass.database
          superclass.database.dup.freeze
        end
      end

      # Set the URI of the CouchDB database to map for this class
      def database=(uri)
        @connection = nil
        if uri.nil?
          @database = nil
        else
          @database = uri.is_a?(URI) ? uri.dup : URI.parse(uri)
          @user     = URI.decode(@database.user) if @database.user
          @password = URI.decode(@database.password) if @database.password
        end
      end
      alias :set_database :database=

      # Gets the user for REST HTTP authentication.
      def user
        # Not using superclass_delegating_reader. See +site+ for explanation
        if defined?(@user)
          @user
        elsif superclass != Object && superclass.user
          superclass.user.dup.freeze
        end
      end

      # Sets the user for REST HTTP authentication.
      def user=(user)
        @connection = nil
        @user = user
      end

      # Gets the password for REST HTTP authentication.
      def password
        # Not using superclass_delegating_reader. See +site+ for explanation
        if defined?(@password)
          @password
        elsif superclass != Object && superclass.password
          superclass.password.dup.freeze
        end
      end

      # Sets the password for REST HTTP authentication.
      def password=(password)
        @connection = nil
        @password = password
      end

      # Sets the number of seconds after which requests to the REST API should time out.
      def timeout=(timeout)
        @connection = nil
        @timeout = timeout
      end

      # Gets tthe number of seconds after which requests to the REST API should time out.
      def timeout
        if defined?(@timeout)
          @timeout
        elsif superclass != Object && superclass.timeout
          superclass.timeout
        end
      end

      # An instance of CouchResource::Connection that is the base connection to the remote service.
      # The +refresh+ parameter toggles whether or not the connection is refreshed at every request
      # or not (defaults to <tt>false</tt>).
      def connection(reflesh = false)
        if defined?(@connection) || superclass == Object
          @connection = Connection.new(database) if reflesh || @connection.nil?
          @connection.user = user if user
          @connection.password = password if password
          @connection.timeout = timeout if timeout
          @connection
        else
          superclass.connection
        end
      end

      # Get the document path specified by the document id
      def document_path(id, query_options=nil)
        "#{File.join(database.path, id)}#{query_string(query_options)}"
      end

      # Returns the path of _all_docs API
      def all_docs_path(query_options=nil)
        document_path("_all_docs", query_options)
      end

      # Returns the path of _bulk_docs
      def bulk_docs_path
        document_path("_bulk_docs")
      end

      def query_string(query_options=nil)
        # compatibility :count and :limit
        if query_options.nil? || query_options.empty?
          nil
        else
          q = query_options.dup
          q[:limit] = q.delete(:count) if q.has_key?(:count)
          "?#{q.to_query}"
        end

      end

      # Get whether the document specified by <tt>id</tt> exists or not
      # options are
      # * <tt>:rev</tt> - An string value determining the revision of the document.
      def exists?(id, options=nil)
        if id
          headers = {}
          headers["If-Match"] = options[:rev].to_json if options[:rev]
          path = document_path(id, options)
          result = connection.head(path, headers)
        end
      end

      # Get the document revisions specified by <tt>id</ttd>
      # This method returns an array including revision numbers.
      # If the second argument, <tt>detailed</tt>, is true, each element in the result array is
      # a Hash which contains 2 key, "status" and "revision".
      # If false, each element is a string which represents revision number.
      def get_revs(id, detailed = false)
        if id
          if detailed
            path = document_path(id, { :revs_info => true })
            result = connection.get(path)
            result[:_revs_info].map { |r| r.symbolize_keys! }
          else
            path = document_path(id, { :revs => true })
            result = connection.get(path)
            result[:_revs]
          end
        end
      end

      #
      # Find the existant document and returns the document object mapped to this class.
      # ==== Examples
      #   Document.find(1)
      #   Document.find("abceef")
      #   Document.find(1, 2, 3)
      #   Document.find([1,2,3])
      #   Document.find(1,:rev => 123456)
      #
      # Note that when the first argument is one of :first, :last or :all,
      # this finder method requests a view name to retrieve documents.
      # In this case options can be the same as CouchDB's querying options (http://wiki.apache.org/couchdb/HttpViewApi).
      #  * <tt>key</tt>            - an object value determining key parameter.
      #  * <tt>startkey</tt>       - an object value determining startkey parameter.
      #  * <tt>startkey_docid</tt> - a string value determiming startkey_docid parameter.
      #  * <tt>endkey</tt>         - an object value determining endkey parameter.
      #  * <tt>endkey_docid</tt>   - a string value determiming startkey_docid parameter.
      #  * <tt>count</tt>          - an integer value determining count parameter.
      #  * <tt>descending</tt>     - a boolean value determining descending parameter.
      #  * <tt>skip</tt>           - an integer value determining skip parameter.
      #  * <tt>group</tt>          - an boolean value determining group parameter.
      #  * <tt>group_level</tt>    - an integer value determining gropu_level parameter.
      #
      # Common Options
      #  * return_raw_hash       - if set true, finder method returns row hash of the response
      #
      # ==== Examples
      #   Document.find(:first, "design_name", "view_name")
      #   Document.find(:first, "design_name", "view_name", :key => "abcd")
      #   Document.find(:first, "design_name", "view_name",
      #                 :startkey => ["abcd"], :endkey => ["abcd", "ZZZZ"],
      #                 :descending => true)
      #   Document.find(:last,  "design_name", "view_name")
      #   Document.find(:all,   "design_name", "view_name")
      def find(*args)
        options = args.extract_options!
        case args.first
        when :first, :last, :all
          raise ArgumentError.new("Design name must be specified. ") unless args[1]
          raise ArgumentError.new("View name must be specified. ") unless args[2]
          send("find_#{args.first}",  args[1], args[2], options)
        else
          find_from_ids(*(args << options))
        end
      end

      # Returns human readable attribute name
      def human_attribute_name(attribute_key_name) #:nodoc:
        attribute_key_name.humanize
      end

      # Execute bulk_docs transaction.
      # Each element in the <tt>array</tt> is passed to the "docs" member in the request body.
      #
      # This method returns the raw hash of JSON from CouchDB.
      #
      # Examples)
      #  bulk_docs([1,2,3]) --->
      #     POST /{db}/_bulk_docs
      #
      #     { "docs" : [1,2,3] }
      #
      #  bulk_docs([{ :_id => "1", :_rev => "1234", :foo      => "bar" },
      #             { :_id => "1", :_rev => "5678", :_deleted => true }]) --->
      #     POST /{db}/_bulk_docs
      #
      #     { "docs" : [
      #           { "_id" : "1" , "_rev" : "1234", "foo"      : "bar" },
      #           { "_id" : "2" , "_rev" : "5678", "_deleted" : true },
      #        ] }
      #
      def bulk_docs(array = [])
        document = { :docs => array }
        logger.debug "CouchResource::Connection#post #{bulk_docs_path}"
        logger.debug document.to_json
        result = connection.post(bulk_docs_path, document.to_json)
        logger.debug result.inspect
        result
      end

      def default
        obj = self.new
        (self.read_inheritable_attribute(:attribute_members) || {}).each do |name, option|
          if option.has_key?(:default)
            default = option[:default]
            if default.is_a?(Proc)
              obj.set_attribute(name, default.call())
            else
              obj.set_attribute(name, default)
            end
          end
        end
        obj
      end

      private
      def find_first(design, view, options)
        path = view_path(design, view, options)
        logger.debug "CouchResource::Connection#get #{path}"
        result = self.connection.get(path)
        logger.debug result.to_json
        first = result["rows"].first
        if first
          if options[:return_raw_hash]
            result
          else
            obj = new(first["value"])
            # invoke explicit callback
            obj.send(:after_find) rescue NoMethodError
            obj
          end
        else
          nil
        end
      end

      def find_last(design, view, options)
        path = view_path(design, view, options)
        logger.debug "CouchResource::Connection#get #{path}"
        result = self.connection.get(path)
        logger.debug result.to_json
        last = result["rows"].last
        if last
          if options[:return_raw_hash]
            result
          else
            obj = new(last["value"])
            # invoke explicit callback
            obj.send(:after_find) rescue NoMethodError
            obj
          end
        else
          nil
        end
      end

      def find_all(design, view, options)
        #
        # paginate options
        #   direction :
        #   expected_offset : when paginating
        #
        # About expected_offset :
        # Sometimes paginate feature returns unexpected option because the offset is incorrect.
        # It seems to be caused by CouchDB BUG (Couch-135)
        # keep watching on http://issues.apache.org/jira/browse/COUCHDB-135
        #
        # The offset parameter CouchDB returns is not reliable so that we can use expected_offset to calculate the correct offset.
        #
        # ** /NOTES FOR THE CURRENT IMPLEMENTATION **
        #
        paginate_options = {}
        [:direction, :expected_offset, :initial_startkey, :initial_endkey].each do |key|
          paginate_options[key] = options.delete(key)       if options.has_key?(key)
        end

        # process requset for view
        result = get_view_result(design, view, options)
        # check if design document has reduce function or not
        view_def = self.get_view_definition(design, view)
        unless view_def.has_key?(:reduce)
          _prev,_next = calculate_pagenate_option(options, paginate_options, result)
          result[:previous] = _prev
          result[:next]     = _next
        end
        if options[:return_raw_hash]
          result
        else
          value_or_doc = options[:include_docs] ? "doc" : "value"
          {
            :next       => result[:next],
            :previous   => result[:previous],
            :total_rows => result[:total_rows],
            :offset     => result[:offset],
            :rows       => result[:rows].map { |row|
              obj = new(row[value_or_doc])
              # invoke explicit callback
              obj.send(:after_find) rescue NoMethodError
              obj
            }
          }
        end
      end

      def get_view_result(design, view, options)
        path = view_path(design, view, options)
        result = nil
        if options.has_key?(:keys)
          logger.debug "CouchResource::Connection#post #{path}"
          result = self.connection.post(path, {:keys => options[:keys]}.to_json)
        else
          logger.debug "CouchResource::Connection#get #{path}"
          result = self.connection.get(path)
        end
        logger.debug result.to_json
        result
      end

      def calculate_pagenate_option(request_options, paginate_options, result)
        total_count = result[:total_rows]
        offset      = result[:offset]
        row_count   = result[:rows].length
        if row_count < total_count
          request_count = request_options[:count]
          request_desc  = request_options.has_key?(:descending) && request_options[:descending]
          #
          # calculate pagination if request_count is set and total_count has te value
          #   note:  total_count should be nil if reduce is executed
          #
          if !request_count.nil? && !total_count.nil?
            # calculate paginate option
            logger.debug " *** CouchResource Pagination Calculation  *** "
            logger.debug "  total_count      : #{total_count}"
            logger.debug "  request_count    : #{request_count}"
            logger.debug "  row_count        : #{row_count}"
            logger.debug "  offset           : #{offset}"
            logger.debug "  direction        : #{paginate_options[:direction]}"
            logger.debug "  initial_startkey : #{paginate_options[:initial_endkey]}"
            logger.debug "  initial_endkey   : #{paginate_options[:initial_endkey]}"
            next_option     = {}
            previous_option = {}
            if paginate_options.has_key?(:expected_offset) && request_options.has_key?(:skip)
              old = offset
              logger.debug " CouchDB offset bug(COUCH-135) workaround : Offset change from #{old} to offset in view point of #{paginate_options[:direction]}."
              offset = paginate_options[:expected_offset].to_i
            end
            # Direction handling to calculate next and previous expected offset.
            if paginate_options.has_key?(:direction)
              case paginate_options[:direction].to_s
              when "previous"
                result[:rows].reverse!
                # On previous pagination the original desc option is the reverse to that of requested.
                request_desc = !request_desc
                if row_count < request_count
                  logger.debug "CouchResource : The count of fetched rows is shorter than that of requested"
                  previous_option[:expected_offset]  = -1
                  if row_count == 0
                    logger.debug "CouchResource : reached over in the previous operation"
                    # this may be the same option as first request. (:skip is not supported)
                    next_option[:startkey]        = paginate_options[:initial_startkey]   if paginate_options.has_key?(:initial_endkey)
                    next_option[:endkey]          = paginate_options[:initial_endkey]     if paginate_options.has_key?(:initial_startkey)
                    next_option[:descending]      = request_desc
                    next_option[:count]           = request_count
                  else
                    # this code may not be reached ... if the client keeps pagination options correctly.
                    next_option[:startkey]         = result[:rows].last["key"]
                    next_option[:startkey_docid]   = result[:rows].last["id"]
                    next_option[:endkey]           = paginate_options[:initial_endkey]   if paginate_options.has_key?(:initial_endkey)
                    next_option[:descending]       = request_desc
                    next_option[:count]            = request_count
                    next_option[:skip]             = 1
                    next_option[:expected_offset]  = total_count - offset
                  end
                else
                  # [previous_option]
                  previous_option[:startkey]        = result[:rows].first["key"]
                  previous_option[:startkey_doc_id] = result[:rows].first["id"]
                  previous_option[:endkey]          = paginate_options[:initial_startkey] if paginate_options.has_key?(:initial_startkey)
                  previous_option[:descending]      = !request_desc
                  previous_option[:count]           = request_count
                  previous_option[:skip]            = 1
                  previous_option[:expected_offset] = offset + previous_option[:count]
                  # [next_option] :
                  # CouchDB options
                  next_option[:startkey]         = result[:rows].last["key"]
                  next_option[:startkey_docid]   = result[:rows].last["id"]
                  next_option[:endkey]           = paginate_options[:initial_endkey]   if paginate_options.has_key?(:initial_endkey)
                  next_option[:descending]       = request_desc
                  next_option[:count]            = request_count
                  next_option[:skip]             = 1
                  next_option[:expected_offset]  = total_count - offset
                end
              when "next"
                if row_count < request_count
                  logger.debug "CouchResource : The count of fetched rows is shorter than that of requested"
                  # [previous_option]
                  if row_count == 0
                    logger.debug "CouchResource : reached over in the next operation"
                    previous_option[:startkey]        = paginate_options[:initial_endkey]   if paginate_options.has_key?(:initial_endkey)
                    previous_option[:endkey]          = paginate_options[:initial_startkey] if paginate_options.has_key?(:initial_startkey)
                    previous_option[:descending]      = !request_desc
                    previous_option[:count]           = request_count
                  else
                    previous_option[:startkey]        = result[:rows].first["key"]
                    previous_option[:startkey_doc_id] = result[:rows].first["id"]
                    previous_option[:endkey]          = paginate_options[:initial_startkey] if paginate_options.has_key?(:initial_startkey)
                    previous_option[:descending]      = !request_desc
                    previous_option[:count]           = request_count
                    previous_option[:skip]            = 1
                    previous_option[:expected_offset] = total_count - offset
                  end
                  # [next_option] :
                  # just set paginate options (no more next docs)
                  next_option[:expected_offset]  = -1
                else
                  previous_option[:startkey]        = result[:rows].first["key"]
                  previous_option[:startkey_doc_id] = result[:rows].first["id"]
                  previous_option[:endkey]          = paginate_options[:initial_startkey] if paginate_options.has_key?(:initial_startkey)
                  previous_option[:descending]      = !request_desc
                  previous_option[:count]           = request_count
                  previous_option[:skip]            = 1
                  previous_option[:expected_offset] = total_count - offset
                  # [next_option] :
                  # CouchDB options
                  next_option[:startkey]         = result[:rows].last["key"]
                  next_option[:startkey_docid]   = result[:rows].last["id"]
                  next_option[:endkey]           = paginate_options[:initial_endkey]   if paginate_options.has_key?(:initial_endkey)
                  next_option[:descending]       = request_desc
                  next_option[:count]            = request_count
                  next_option[:skip]             = 1
                  # Paginate options
                  next_option[:expected_offset]  = offset + next_option[:count]
                end
              else
                raise ArgumentError.new("paginate_options :direction should be 'previous' or 'next'.")
              end
              # common Paginate options
              previous_option[:direction] = "previous"
              next_option[:direction]     = "next"
              # keep initial_state
              previous_option[:initial_startkey] = paginate_options[:initial_startkey] if paginate_options.has_key?(:initial_startkey)
              previous_option[:initial_endkey]   = paginate_options[:initial_endkey]   if paginate_options.has_key?(:initial_endkey)
              next_option[:initial_startkey]     = paginate_options[:initial_startkey] if paginate_options.has_key?(:initial_startkey)
              next_option[:initial_endkey]       = paginate_options[:initial_endkey]   if paginate_options.has_key?(:initial_endkey)
            else
              #
              # first request for pagination
              #
              logger.debug "CouchResource : first request for pagination"
              previous_option[:direction]        = "previous"
              previous_option[:expected_offset]  = -1
              previous_option[:initial_startkey] = request_options[:startkey]  if request_options.has_key?(:startkey)
              previous_option[:initial_endkey]   = request_options[:endkey]    if request_options.has_key?(:endkey)

              if row_count < request_count
                logger.debug "CouchResource : The count of fetched rows is shorter than that of requested"
                # [next_option] :
                # just set paginate options
                next_option[:direction]        = "next"
                next_option[:expected_offset]  = -1
                next_option[:initial_startkey] = request_options[:startkey] if request_options.has_key?(:startkey)
                next_option[:initial_endkey]   = request_options[:endkey]   if request_options.has_key?(:endkey)
              else
                # [next_option] :
                # CouchDB options
                next_option[:startkey]         = result[:rows].last["key"]
                next_option[:startkey_docid]   = result[:rows].last["id"]
                next_option[:endkey]           = request_options[:endkey] if request_options.has_key?(:endkey)
                next_option[:count]            = request_count
                next_option[:skip]             = 1
                next_option[:descending]       = request_desc
                # Paginate options
                next_option[:direction]        = "next"
                next_option[:expected_offset]  = offset + next_option[:count]
                next_option[:initial_startkey] = request_options[:startkey] if request_options.has_key?(:startkey)
                next_option[:initial_endkey]   = request_options[:endkey]   if request_options.has_key?(:endkey)
              end
            end
            [previous_option, next_option]
          end
        end
      end

      def find_from_ids(*args)
        options = args.extract_options!
        ids = args.flatten
        query_option = {}
        headers      = {}
        query_option[:rev] = options[:rev] if options[:rev]
        if ids.length > 1 # two or more ids
          path = all_docs_path((query_option || {}).update({:include_docs => true}))
          post = { :keys => ids }
          logger.debug "CouchResource::Connection#post #{path}"
          docs = connection.post(path, post.to_json)["rows"]
          logger.debug docs.to_json
          docs.map { |doc|
            obj = new(doc["doc"])
            obj.send(:after_find) rescue NoMethodError
            obj
          }
        else
          # return one document.
          path   = document_path(ids, query_option)
          logger.debug "CouchResource::Connection#get #{path}"
          result = connection.get(path, headers)
          logger.debug result.to_json
          obj = new(result)
          obj.send(:after_find) rescue NoMethodError
          obj
        end
      end
    end

    def initialize(attributes = nil)
      if attributes
        (self.class.read_inheritable_attribute(:attribute_members) || {}).each do |name, option|
          self.set_attribute(name, attributes[name.to_sym])
        end
        @id  = attributes[:_id] ? attributes[:_id] : nil
        @rev = attributes[:_rev] ? attributes[:_rev] : nil
      end
      # invoke explicit callback
      self.after_initialize rescue NoMethodError
    end

    def new?
      rev.nil?
    end
    alias :new_record? :new?

    def id
      @id
    end
    alias :_id :id

    def id=(id)
      @id=id
    end
    alias :_id= :id=

    def rev
      @rev
    end
    alias :_rev :rev

    def revs(detailed = false)
      new? ? [] : self.class.get_revs(self.id, detailed)
    end

    def save
      result = create_or_update
    end

    def save!
      save || raise(RecordNotSaved)
    end

    def update_attribute(name, value)
      send("#{name.to_s}=", value)
      save
    end

    def destroy
      if self.new_record?
        false
      else
        # [TODO] This does not work on couchdb 0.9.0 (returns 400 'Document rev and etag have different values.')
        # connection.delete(document_path, {"If-Match" => rev })
        connection.delete(document_path)
        @rev = nil
        true
      end
    end

    def exists?
      if rev
        !new? && self.class.exists?(id, { :rev => rev })
      else
        !new? && self.class.exists?(id)
      end
    end

    # Get the path of the object.
    def document_path
      if rev
        self.class.document_path(id, { :rev => rev })
      else
        self.class.document_path(id)
      end
    end

    # Get the json representation of the object.
    def to_json
      h = self.to_hash
      h[:id]  = self.id  if self.id
      h[:rev] = self.rev if self.rev
      h.to_json
    end

    # Get the xml representation of the object, whose root is the class name.
    def to_xml
      h = self.to_hash
      h[:id]  = self.id  if self.id
      h[:rev] = self.rev if self.rev
      h.to_xml(:root => self.class.to_s)
    end

    protected
    def connection(reflesh = false)
      self.class.connection(reflesh)
    end

    def create_or_update
      new? ? create : update
    end

    def create
      set_magic_attribute_values_on_create
      result = if id
                 document = { "_id" =>  id }.update(to_hash)
                 logger.debug "CouchResource::Connection#put #{self.document_path}"
                 logger.debug document.to_json
                 connection.put(self.document_path, document.to_json)
               else
                 document = to_hash
                 logger.debug "CouchResource::Connection#post #{self.class.database.path}"
                 logger.debug document.to_json
                 connection.post(self.class.database.path, document.to_json)
               end
      if result
        set_id_and_rev(result[:id], result[:rev])
        true
      else
        false
      end
    end

    def update
      set_magic_attribute_values_on_update
      # [TODO] This does not work on couchdb 0.9.0 (returns 400 'Document rev and etag have different values.')
      # document = { "_id" => self.id, "_rev" => self.rev }.update(to_hash)
      document = { "_id" => self.id }.update(to_hash)
      logger.debug "CouchResource::Connection#put #{self.document_path}"
      logger.debug "If-Match: #{rev.to_json}"
      logger.debug document.to_json
      result = connection.put(self.document_path, document.to_json, {"If-Match" => rev.to_json})
      if result
        set_id_and_rev(result[:id], result[:rev])
        true
      else
        false
      end
    end

    def set_magic_attribute_values_on_create
      self.created_at = Time.now   if get_attribute_option(:created_at)
      self.created_on = Time.today if get_attribute_option(:created_on)
      self.updated_at = Time.now   if get_attribute_option(:updated_at)
      self.updated_on = Time.today if get_attribute_option(:updated_on)
    end

    def set_magic_attribute_values_on_update
      self.updated_at = Time.now   if get_attribute_option(:updated_at)
      self.updated_on = Time.today if get_attribute_option(:updated_on)
    end

    def set_id_and_rev(id, rev)
      @id  = id
      @rev = rev
    end
  end
end
