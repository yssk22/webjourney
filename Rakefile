#
# WebJourney Utility Task Script
#
# Common Environemnt Arguments
#   FORCE : if set true, console confirmations are skipped by enforcing to answer 'y'. (The default is nil)
#
require 'pathname'
require 'rubygems'
require 'json'
require 'yaml'
require 'erb'
require File.join(File.dirname(__FILE__), "relax/relax_client/lib/relax_client")

#
# initialize constants from configuration
#
CONFIG_PATH       = File.join(File.dirname(__FILE__), "config/webjourney.json")
CONFIG_LOCAL_PATH = File.join(File.dirname(__FILE__), "config/webjourney.local.json")
config = RelaxClient.config

# container and db mappping
CONTAINER_TO_DB = {
  "webjourney" => config["containers"]["webjourney"],
  "opensocial" => config["containers"]["opensocial"]
}
DB_TO_CONTAINERS = {}
CONTAINER_TO_DB.each do |container, db_uri|
  if DB_TO_CONTAINERS.has_key?(db_uri)
    DB_TO_CONTAINERS[db_uri] << container
  else
    DB_TO_CONTAINERS[db_uri] = [container]
  end
end

HTTP_ROOT            = "http://#{config["httpd"]["servername"]}"
TOP_PAGE_PATH        = File.join(CONTAINER_TO_DB["webjourney"].split("/").last, "_design/webjourney/_show/page/pages:top")
IMPORT_TEST_FIXTURES = config["misc"]["import_test_fixtures"]

desc("Initialize Environemnt")
task :initialize do
  CONTAINER_TO_DB.each do |key, db|
    dir = File.join(File.dirname(__FILE__), "relax/containers/#{key}")
    step("Configuration Info about #{key}") do
      puts "Database  :  #{db}"
      puts "Directory :  #{dir}"
    end
  end
  Rake::Task["initialize:db"].invoke()
  Rake::Task["initialize:couchapp"].invoke()

  step("WebJourney has been initialized successfully.") do
    puts "Visit your webjourney here:"
    puts
    puts "   #{HTTP_ROOT}/#{TOP_PAGE_PATH}"
    puts
  end
end

namespace :initialize do
  desc("Initialize couchapp design documents")
  task :couchapp do
    CONTAINER_TO_DB.each do |key, db|
      dir = File.join(File.dirname(__FILE__), "relax/containers/#{key}")
      step("Push the application") do
        sh("couchapp push #{dir} #{db}")
      end
    end
  end

  desc("Initialize Database")
  task :db do
    # Database creation for each database
    DB_TO_CONTAINERS.each do |db_uri, container_names|
      db = RelaxClient.for_container(container_names.first)
      step "Database Check" do
        if db.exist?
          confirmed = confirm("Continue with dropping database?") do
            puts "Drop the database."
            db.drop
          end
          unless confirmed
            puts "Initialization canceled."
            exit 0
          end
        end
        puts "Create a database."
        db.create
      end
    end

    # Data Loading
    CONTAINER_TO_DB.each do |container_name, db_uri|
      db = RelaxClient.for_container(container_name)
      dir = container_dir(container_name)
      step("Import initial data set") do
        Dir.glob(File.join(dir, "**/*.json")) do |fname|
          docs = nil
          if fname =~ /.*\.test\.json/
            docs = db.insert_fixtures(fname) if IMPORT_TEST_FIXTURES
          else
            docs = db.import_from_file(fname)
          end
          if docs
            puts "#{File.basename(fname)} - #{docs.length} documents"
          end
        end
      end
    end
  end
end

namespace :app do
  desc("Generate a new OpenSocial application directory")
  task :generate do
    name = ENV["NAME"]
    puts "NAME={app_name} should be specified." if blank?(name)
    target = app_dir(name)
    app = {
      "name" => name,
      "description" => "Your application description"
    }

    # couchapp generation
    if File.exist?(target)
      puts "[INFO] couchapp generation was skipped."
    else
      sh("couchapp generate #{target}")
    end

    # gadget xml generation
    xml_path      = File.join(target, "_attachments/gadget.xml")
    if File.exist?(xml_path)
      puts "[INFO] gadget xml generation was skipped."
    else
      xml_template  = dir("config/gadget.template.xml")
      xml = ERB.new(File.read(xml_template), nil, '-').result(binding)
      File.open(xml_path, "w") do |f|
        f.write(xml)
      end
      puts "[INFO] generated on #{xml_path}."
    end
  end

  desc("Register a OpenSocial application in the current environment.")
  task :register do
  end

  desc("Unregister a OpenSocial application from the current environment.")
  task :unregister do
  end

  desc("List the OpenSocial applications in the current environment.")
  task :list do
  end

end

namespace :print do
  desc("Print the VirtualHost configuration for Apache httpd.conf")
  task :httpd_conf do
    template_path = File.join(File.dirname(__FILE__), "config/httpd.template.conf")
    # setup binding parameters
    httpd = {
      "servername" => config["httpd"]["servername"],
      "docroot"    => Pathname.new(File.join(File.dirname(__FILE__), "site")).realpath
    }
    ERB.new(File.read(template_path), nil, '-').run(binding)
  end
end

# End of Task
# ****************************************************
# Belows are the utility method for tasks.
def blank?(str)
  str.nil? || str == ""
end

def dir(name)
  File.join(File.dirname(__FILE__), name)
end

def container_dir(name)
  File.join(File.dirname(__FILE__), "relax/containers/#{name}")
end

def app_dir(name)
  File.join(File.dirname(__FILE__), "relax/apps/#{name}")
end

#
# Execute the block with announcing the step description.
#
def step(step, &block)
  puts "*** #{step}"
  block.call()
  puts ""
end

#
# Execute the block with the y/n confirmation.
#
def confirm(msg, &block)
  if ENV["FORCE"] == "true"
    puts "#{msg} [y/n]y"
    block.call()
    return true
  end
  print "#{msg} [y/n]"
  c = $stdin.gets().chomp!
  case c
  when "y"
    block.call()
    return true
  when "n"
    return false
  else
    puts "Please input y or n."
    confirm(msg, &block)
  end
end
