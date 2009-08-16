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

WEBJOURNEY_ENV = ENV["WEBJOURNEY_ENV"] || "development"
config = YAML.load(File.read(File.join(File.dirname(__FILE__), "config/webjourney.yml")))

# app and db mappping
APPNAME_TO_DB = {
  "webjourney" => config[WEBJOURNEY_ENV]["couchdb"]["webjourney"],
  "opensocial" => config[WEBJOURNEY_ENV]["couchdb"]["opensocial"]
}
DB_TO_APPNAMES = {}
APPNAME_TO_DB.each do |appname, db_uri|
    if DB_TO_APPNAMES.has_key?(db_uri)
      DB_TO_APPNAMES[db_uri] << appname
    else
      DB_TO_APPNAMES[db_uri] = [appname]
    end
end


HTTP_ROOT            = "http://#{config[WEBJOURNEY_ENV]["httpd"]["servername"]}"
TOP_PAGE_PATH        = File.join(APPNAME_TO_DB["webjourney"].split("/").last, "_design/webjourney/_show/page/pages:top")
IMPORT_TEST_FIXTURES = config[WEBJOURNEY_ENV]["misc"]["import_test_fixtures"]

desc("Initialize Environemnt")
task :initialize do
  APPNAME_TO_DB.each do |key, db|
    dir = File.join(File.dirname(__FILE__), "relax/apps/#{key}")
    step("Configuration Info about #{key}") do
      puts "Database  :  #{db}"
      puts "Directory :  #{dir}"
    end
  end
  Rake::Task["initialize:db"].invoke()
  Rake::Task["initialize:couchapp"].invoke()

  puts "WebJourney has been initialized successfully."
  puts "Visit your webjourney here:"
  puts
  puts "   #{HTTP_ROOT}/#{TOP_PAGE_PATH}"
  puts
end

namespace :initialize do
  desc("Initialize CouchApp design documents")
  task :couchapp do
    APPNAME_TO_DB.each do |key, db|
      dir = File.join(File.dirname(__FILE__), "relax/apps/#{key}")
      step("Push the application") do
        sh("couchapp push #{dir} #{db}")
      end
    end
  end

  desc("Initialize Database")
  task :db do
    # Database creation for each database
    DB_TO_APPNAMES.each do |db_uri, appnames|
      db = RelaxClient.new(appnames.first)
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
    APPNAME_TO_DB.each do |appname, db_uri|
      db = RelaxClient.new(appname)
      dir = File.join(File.dirname(__FILE__), "relax/apps/#{appname}")
      step("Import initial data set") do
        Dir.glob(File.join(dir, "**/*.json")) do |fname|
          if fname =~ /.*\.test\.json/
            count = import_fixtures(fname, db) if IMPORT_TEST_FIXTURES
          else
            count = import_fixtures(fname, db)
          end
          puts "#{File.basename(fname)} - #{count} documents"
        end
      end
    end
  end
end

task :print_httpd_conf do
  template_path = File.join(File.dirname(__FILE__), "config/httpd.template.conf")
  # setup binding parameters
  httpd = {
    "servername" => config[WEBJOURNEY_ENV]["httpd"]["servername"],
    "docroot"    => Pathname.new(File.join(File.dirname(__FILE__), "site")).realpath
  }
  ERB.new(File.read(template_path), nil, '-').run(binding)
end

def step(step, &block)
  puts "*** #{step}"
  block.call()
  puts ""
end

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

def import_fixtures(fname, db, is_test=false)
  docs = nil
  begin
    docs = JSON.parse(File.read(fname))
    raise "Fixtures should be an Array of JSON." unless docs.is_a?(Array)
  rescue => e
    puts "JSON error detected in #{fname}"
    raise e
  end
  # Importing by bulk_docs
  db.bulk_docs(docs, :all_or_nothing => true)
  docs.length
end
