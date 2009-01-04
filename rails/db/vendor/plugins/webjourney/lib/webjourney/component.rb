require File.join(File.dirname(__FILE__), "component/package")
require File.join(File.dirname(__FILE__), "component/file_tasks")
require File.join(File.dirname(__FILE__), "component/register_tasks")
require File.join(File.dirname(__FILE__), "component/migration_tasks")

WebJourney::Component::Package.send :include, WebJourney::Component::FileTasks
WebJourney::Component::Package.send :include, WebJourney::Component::RegisterTasks
WebJourney::Component::Package.send :include, WebJourney::Component::MigrationTasks
