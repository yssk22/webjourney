require File.join(File.dirname(__FILE__), "component/task/package")
require File.join(File.dirname(__FILE__), "component/task/file_tasks")
require File.join(File.dirname(__FILE__), "component/task/register_tasks")
require File.join(File.dirname(__FILE__), "component/task/migration_tasks")

WebJourney::Component::Task::Package.send :include, WebJourney::Component::Task::FileTasks
WebJourney::Component::Task::Package.send :include, WebJourney::Component::Task::RegisterTasks
WebJourney::Component::Task::Package.send :include, WebJourney::Component::Task::MigrationTasks
