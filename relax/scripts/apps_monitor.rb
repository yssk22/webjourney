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

appdirs = Dir.
  glob(File.join(File.dirname(__FILE__), "../apps/*")).
  select { |dir| File.directory?(dir) }.
  map    { |dir| Pathname.new(dir).realpath.to_s}

env = ENV["WEBJOURNEY_ENV"] || "default"
config = YAML.load(File.read(File.join(File.dirname(__FILE__), "../../config/webjourney.yml")))[env]["couchdb"]

file_updated = lambda {  |stream, ctx, numEvents, paths, marks, eventIDs|
  paths.regard_as('*')
  numEvents.times do |n|
    dir = paths[n]
    appdirs.each do |appdir|
      if dir =~ /^#{appdir}/
        appname = appdir.split("/").last
        uri = config[appname]

        puts ">> Update : #{appname}"
        system("cd #{appdir}; (couchapp push #{uri} 2>&1) > /dev/null")
        puts ">> OK"
      end
    end
  end
}

stream = FSEventStreamCreate(
                             KCFAllocatorDefault,
                             file_updated,
                             nil,
                             appdirs,
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

