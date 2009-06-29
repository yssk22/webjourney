#
# WebJourney Utility Task Script
#
# Common Environemnt Arguments
#   WEBJOURNEY_ENV : webjourney environment name to select configuration. The default is 'default'.
#   FORCE : if set true, console confirmations are skipped by enforcing to answer 'y'. (The default is nil)
#

require 'rubygems'
require 'json'
require 'net/http'
require 'yaml'

env = ENV["WEBJOURNEY_ENV"] || "default"
config = YAML.load(File.read(File.join(File.dirname(__FILE__), "config/webjourney.yml")))

# app and db mappping
APPNAME_TO_DB = {
  "webjourney" => config[env]["couchdb"]["pages"]
}
import_test_fixtures = config[env]["misc"]["import_test_fixtures"]
http_root            = "http://#{config[env]["httpd"]["servername"]}"

desc("Initialize Environemnt")
task :initialize do
  APPNAME_TO_DB.each do |key, db|
    dir = File.join(File.dirname(__FILE__), "relax/apps/#{key}")
    step("Configuration Info about #{key}") do
      puts "Database  :  #{db}"
      puts "Directory :  #{dir}"
    end

    step "Database Check" do
      if db_exists?(db)
        confirmed = confirm("Continue with dropping database?") do
          puts "Drop the database."
          drop_db(db)
        end
        unless confirmed
          puts "Initialization canceled."
          exit 0
        end
      else
        puts "No database exists"
      end
    end

    step("Push the application") do
      sh("couchapp push #{dir} #{db}")
    end

    step("Import initial data set") do
      Dir.glob(File.join(dir, "**/*.json")) do |fname|
        count = if fname =~ /test\.json/    # test fixture
                  import_fixtures(fname, db, true) if import_test_fixtures
                else
                  import_fixtures(fname, db)
                end
        puts "#{File.basename(fname)} - #{count} documents"
      end
    end

  end
end

desc("Display Apache VirtualHost Configuration")
task :display_vhost_config do
end

desc("Display CouchDB Configuration")
task :display_couchdb_config do
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

def db_exists?(db)
  uri = URI.parse(db)
  req = Net::HTTP::Get.new(File.join(uri.path))
  req.basic_auth(uri.user, uri.password)
  Net::HTTP.start(uri.host, uri.port) do |http|
    res = http.request(req)
    res.is_a?(Net::HTTPOK)
  end
end

def drop_db(db)
  uri = URI.parse(db)
  req = Net::HTTP::Delete.new(File.join(uri.path))
  req.basic_auth(uri.user, uri.password)
  Net::HTTP.start(uri.host, uri.port) do |http|
    res = http.request(req)
    raise_http_error(req, res)    unless res.is_a?(Net::HTTPSuccess)
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

  # test fixture should be marked as "is_test_fixture"
  docs = docs.map { |doc| doc["is_test_fixture"] = true; doc }  if is_test

  # Importing by bulk_docs
  uri = URI.parse(db)
  req = Net::HTTP::Post.new(File.join(uri.path, "_bulk_docs"))
  req.basic_auth(uri.user, uri.password)
  req.body = { "docs" => docs, "all_or_nothing" => is_test}.to_json
  Net::HTTP.start(uri.host, uri.port) do |http|
    res = http.request(req)
    json = JSON.parse(res.body)
    raise_http_error(req, res)    unless res.is_a?(Net::HTTPSuccess)
  end
  docs.length
end

def raise_http_error(req, res)
  puts "An error received from Server"
  puts res.body

  puts "Request Body: "
  puts req.body
  raise res.error!
end
