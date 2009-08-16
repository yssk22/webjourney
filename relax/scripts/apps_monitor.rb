#!/usr/bin/ruby
#
# apps_monitor.rb
#
# This script monitors couchapp directory and pushes it automatically when changed.
# This is available on RubyCocoa / OSX only (OSX's FSEvent API is used throught RubyCocoa)
#
require 'pathname'
require 'osx/foundation'
require 'yaml'
OSX.require_framework '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework'
include OSX


# CouchApp monitor
appdirs = Dir.
  glob(File.join(File.dirname(__FILE__), "../apps/*")).
  select { |dir| File.directory?(dir) }.
  map    { |dir| Pathname.new(dir).realpath.to_s}

# Proxy Monitor
proxydir = Pathname.new(File.join(File.dirname(__FILE__), "../opensocial-proxy/lib")).realpath.to_s

env = ENV["WEBJOURNEY_ENV"] || "development"
$config = YAML.load(File.read(File.join(File.dirname(__FILE__), "../../config/webjourney.yml")))[env]["couchdb"]

def push_app(appdir)
  appname = appdir.split("/").last
  uri = $config[appname]
  puts ">> Update : #{appname}"
  system("cd #{appdir}; (couchapp push #{uri} 2>&1) > /dev/null")
  puts ">> OK"
end

def reload_rack(proxydir)
  puts ">> Reload : rack"
  system("cd #{proxydir}; touch ../tmp/restart.txt")
  puts ">> OK"
end

file_updated = lambda {  |stream, ctx, numEvents, paths, marks, eventIDs|
  paths.regard_as('*')
  numEvents.times do |n|
    dir = paths[n]
    appdirs.each do |appdir|
      push_app(appdir) if dir =~ /^#{appdir}/
      reload_rack(proxydir)            if dir =~ /^#{proxydir}/
    end
  end
}

stream = FSEventStreamCreate(
                             KCFAllocatorDefault,
                             file_updated,
                             nil,
                             appdirs + [proxydir],
                             KFSEventStreamEventIdSinceNow,
                             1.0,
                             0)
raise "Failed to create the FSEventStream" unless stream


FSEventStreamScheduleWithRunLoop(
  stream,
  CFRunLoopGetCurrent(),
  KCFRunLoopDefaultMode)

ok = FSEventStreamStart(stream)
raise "Failed to start the FSEventStream" unless ok

puts "Start to monitor applications ... "

begin
  CFRunLoopRun()
rescue Interrupt
  FSEventStreamStop(stream)
  FSEventStreamInvalidate(stream)
  FSEventStreamRelease(stream)
end

