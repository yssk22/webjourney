module WebJourney; end



# Base Architecture Plugins
require File.join(File.dirname(__FILE__), "webjourney/logger")
require File.join(File.dirname(__FILE__), "webjourney/errors")
require File.join(File.dirname(__FILE__), "webjourney/assertion")
require File.join(File.dirname(__FILE__), "webjourney/routes")


# Component Installer
require File.join(File.dirname(__FILE__), "webjourney/component")

# Helpers
require File.join(File.dirname(__FILE__), "webjourney/helpers/widget_helper")
require File.join(File.dirname(__FILE__), "webjourney/helpers/component_helper")
require File.join(File.dirname(__FILE__), "webjourney/helpers/component_page_helper")

# Controllers
require File.join(File.dirname(__FILE__), "webjourney/controllers/application_controller")
require File.join(File.dirname(__FILE__), "webjourney/controllers/component_controller")
require File.join(File.dirname(__FILE__), "webjourney/controllers/component_page_controller")
require File.join(File.dirname(__FILE__), "webjourney/controllers/widget_controller")

# CouchResource Extension (Acts)
require File.join(File.dirname(__FILE__), "webjourney/acts/relationship_permittable")
