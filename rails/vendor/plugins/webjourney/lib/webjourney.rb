module WebJourney # :nodoc:
  module Component # :nodoc:
  end
end

# load framework libraries
require File.join(File.dirname(__FILE__), "webjourney/errors")
require File.join(File.dirname(__FILE__), "webjourney/assertion")

# load framework MVC extension
require File.join(File.dirname(__FILE__), "webjourney/models/features/relationship_based_access_control")
require File.join(File.dirname(__FILE__), "webjourney/controllers/features/role_based_access_control")

require File.join(File.dirname(__FILE__), "webjourney/controllers/application_controller")
require File.join(File.dirname(__FILE__), "webjourney/controllers/resource_controller")

# load component libraries
require File.join(File.dirname(__FILE__), "webjourney/component/routes")
require File.join(File.dirname(__FILE__), "webjourney/component/task/package")
require File.join(File.dirname(__FILE__), "webjourney/component/controllers/features/role_based_access_control")
require File.join(File.dirname(__FILE__), "webjourney/component/controllers/component_controller")
require File.join(File.dirname(__FILE__), "webjourney/component/controllers/page_controller")
require File.join(File.dirname(__FILE__), "webjourney/component/controllers/widget_controller")

