require File.join(File.dirname(__FILE__), "abstract/data_statements")
require File.join(File.dirname(__FILE__), "abstract/schema_statements")
module ActiveRecord
  module ConnectionAdapters # :nodoc
    class AbstractAdapter
      include DataStatements
      include SchemaStatements
    end
  end
end
