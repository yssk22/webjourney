require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require File.dirname(__FILE__) + '/../../config/boot'
require File.dirname(__FILE__) + '/../../config/environment'
include RakeUtil

namespace :wj do
  namespace :dev do
    desc("Reset all databases used in development")
    task :reset do
      WjComponent.find(:all).map do |component|
        drop_couchdb_for_component(component.directory_name)
      end
      Rake::Task["couchdb:drop"].invoke
      Rake::Task["db:drop"].invoke
      Rake::Task["wj:dev:setup"].invoke
    end

    desc("Setup development environment")
    task :setup do
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["couchdb:create"].invoke
      # Setup initial data
      Rake::Task["db:fixtures:load"].invoke
      Rake::Task["couchdb:fixtures:load"].invoke
      ["system", "sticky", "test", "blog"].each do |component|
        ENV["COMPONENT"] = component
        pkg = WebJourney::Component::Task::Package.new(component)
        pkg.install(false)
        create_couchdb_for_component(component)
      end

      top_page = WjPage.top rescue nil
      if top_page.nil?
        top_page = WjPage.new(:_id => WjPage::TopPageId, :title => "Top Page", :owner_login_name => WjUser::BuiltIn::Administrator.me.login_name)
        top_page.save!
      end
    end

    desc("Register a component specified with COMPONENT=x")
    task :register do
      component = ENV["COMPONENT"]
      raise "Component name must be specified with 'COMPONENT=x'" unless component
      pkg = WebJourney::Component::Task::Package.new(component)
      pkg.install(false)
      create_couchdb_for_component(component)
    end

    task :unregister do
      component = ENV["COMPONENT"]
      raise "Component name must be specified with 'COMPONENT=x'" unless component
      pkg = WebJourney::Component::Task::Package.new(component)
      pkg.uninstall(false)
      drop_couchdb_for_component(component)
    end
  end
end
