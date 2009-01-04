# loading ruby class extensions
#Dir::foreach(File.join(File.dirname(__FILE__), "lib/ruby_ext"))  do |f|
#   require File.join(File.dirname(__FILE__), "lib/ruby_ext", f) if f =~ /.rb$/
#end

# loading rails class extensions
require File.join(File.dirname(__FILE__), "lib/ext/active_support/active_support")
require File.join(File.dirname(__FILE__), "lib/ext/active_record/active_record")
require File.join(File.dirname(__FILE__), "lib/ext/action_pack/lib/action_controller")
require File.join(File.dirname(__FILE__), "lib/ext/action_pack/lib/action_view")

# loading webjourney original modules
require File.join(File.dirname(__FILE__), "lib/webjourney.rb")

