#
# loading rails class extensions(include local fixes)
#

require File.join(File.dirname(__FILE__), "lib/ext/active_support/active_support")
require File.join(File.dirname(__FILE__), "lib/ext/active_record/active_record")
require File.join(File.dirname(__FILE__), "lib/ext/action_pack/lib/action_controller")
require File.join(File.dirname(__FILE__), "lib/ext/action_pack/lib/action_view")

#
# loading webjourney original plugins
#

require File.join(File.dirname(__FILE__), "lib/webjourney.rb")

