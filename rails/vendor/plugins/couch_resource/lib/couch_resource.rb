require File.join(File.dirname(__FILE__), 'couch_resource/struct')
require File.join(File.dirname(__FILE__), 'couch_resource/validations')
require File.join(File.dirname(__FILE__), 'couch_resource/callbacks')
require File.join(File.dirname(__FILE__), 'couch_resource/view')
require File.join(File.dirname(__FILE__), 'couch_resource/base')

module CouchResource
  Base.class_eval do
    include Struct
    include Validations
    include View
    alias_method_chain :save, :validation
    alias_method_chain :save!, :validation

    include Callbacks
    # validation method chain
  end
end

module CouchResource
  class SubResource
    include Struct
    include Validations
  end
end
