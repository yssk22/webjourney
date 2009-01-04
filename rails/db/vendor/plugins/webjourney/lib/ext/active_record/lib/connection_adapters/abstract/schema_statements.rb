module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module SchemaStatements
      alias :org_index_name :index_name
      def index_name(table_name, options) #:nodoc:
        if Hash === options && options[:column]
          Array(options[:column]) * '_'
        else
          org_index_name(table_name, options)
        end
      end
    end
  end
end
