#
# WebJourney Utility Task Script
#
# Common Environemnt Arguments
#   WEBJOURNEY_ENV : webjourney environment name to select configuration. The default is 'default'.
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
WEBJOURNEY_ENV = ENV["WEBJOURNEY_ENV"] || "development"
config = YAML.load(File.read(File.join(File.dirname(__FILE__), "config/webjourney.yml")))

# container and db mappping
CONTAINER_TO_DB = {
  "webjourney" => config[WEBJOURNEY_ENV]["couchdb"]["webjourney"],
  "opensocial" => config[WEBJOURNEY_ENV]["couchdb"]["opensocial"]
}
DB_TO_CONTAINERS = {}
CONTAINER_TO_DB.each do |container, db_uri|
    if DB_TO_CONTAINERS.has_key?(db_uri)
      DB_TO_CONTAINERS[db_uri] << container
    else
      DB_TO_CONTAINERS[db_uri] = [container]
    end
end

HTTP_ROOT            = "http://#{config[WEBJOURNEY_ENV]["httpd"]["servername"]}"
TOP_PAGE_PATH        = File.join(CONTAINER_TO_DB["webjourney"].split("/").last, "_design/webjourney/_show/page/pages:top")
IMPORT_TEST_FIXTURES = config[WEBJOURNEY_ENV]["misc"]["import_test_fixtures"]

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
      db = RelaxClient.new(container_names.first)
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
      db = RelaxClient.new(container_name)
      dir = File.join(File.dirname(__FILE__), "relax/containers/#{container_name}")
      step("Import initial data set") do
        Dir.glob(File.join(dir, "**/*.json")) do |fname|
          if fname =~ /.*\.test\.json/
            docs = db.insert_fixtures(fname) if IMPORT_TEST_FIXTURES
          else
            docs = db.import_from_file(fname)
          end
          puts "#{File.basename(fname)} - #{docs.length} documents"
        end
      end
    end
  end
end

desc("Print the VirtualHost configuration for Apache httpd.conf")
task :print_httpd_conf do
  template_path = File.join(File.dirname(__FILE__), "config/httpd.template.conf")
  # setup binding parameters
  httpd = {
    "servername" => config[WEBJOURNEY_ENV]["httpd"]["servername"],
    "docroot"    => Pathname.new(File.join(File.dirname(__FILE__), "site")).realpath
  }
  ERB.new(File.read(template_path), nil, '-').run(binding)
end

# End of Task
# ****************************************************
# Belows are the utility method for tasks.

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
