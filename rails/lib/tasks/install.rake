require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require File.dirname(__FILE__) + '/../../config/boot'
require File.dirname(__FILE__) + '/../../config/environment'
include RakeUtil
namespace :wj do
  desc("Install base platform for WebJourney")
  task :install do
    puts "Configure databases ... "
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["couchdb:create"].invoke
    # base data
    Rake::Task["db:fixtures:load"].invoke
    Rake::Task["couchdb:fixtures:load"].invoke
    # base component
    install_components("system", "sticky")
    puts "WebJourney has been installed successfully!!"
  end

  task :uninstall do
    WjComponent.find(:all).map do |component|
      drop_couchdb_for_component(component.directory_name)
    end
    Rake::Task["couchdb:drop"].invoke
    Rake::Task["db:drop"].invoke
  end
end
