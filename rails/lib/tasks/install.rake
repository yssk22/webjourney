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

    # componse top page
    puts "Composing the top page ... "

    initial_widgets = []
    initial_widgets << {:component => "sticky", :widget => "html"}
    initial_widgets << {:component => "sticky", :widget => "text"}
    top = WjPage.top
    top.compose_widget_instance_layout({:center => initial_widgets})
    top.save!
    instances = top.get_current_widget_instances()
    # puts instances.inspect
    welcome = instances.first
    welcome.title = "Welcome to WebJourney"
    welcome.parameters[:html] = <<-EOS
<p>WebJourney has been installed successfully!!</p>
EOS
    welcome.save
    # LICENSE NOTE
    license = instances.last
    license.title = "LICENSE"
    license.parameters[:text] = File.open(File.join(RAILS_ROOT, "MIT_LICENSE"), "r") { |f| f.read }
    license.save

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
