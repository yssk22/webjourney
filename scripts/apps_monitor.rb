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
require 'rubygems'
require 'json'
require File.join(File.dirname(__FILE__), "../lib/relax_client")
OSX.require_framework '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework'
include OSX


# CouchApp monitor
appdirs = Dir.
  glob(File.join(File.dirname(__FILE__), "../relax/gadgets/*")).
  select { |dir| File.directory?(dir) }.
  map    { |dir| Pathname.new(dir).realpath.to_s}
appdirs = appdirs + Dir.
  glob(File.join(File.dirname(__FILE__), "../relax/containers/*")).
  select { |dir| File.directory?(dir) }.
  map    { |dir| Pathname.new(dir).realpath.to_s}

# Proxy Monitor
proxydir = Pathname.new(File.join(File.dirname(__FILE__), "../proxy/rack/lib")).realpath.to_s


global_config = File.join(File.dirname(__FILE__), "../config/webjourney.json")
local_config  = File.join(File.dirname(__FILE__), "../config/webjourney.local.json")
$config = JSON(File.read(global_config)).
  update(JSON(File.read(local_config)))

def push_app(appdir)
  appname = appdir.split("/").last
  uri = nil
  if $config["containers"][appname]
    uri = RelaxClient.for_container(appname).uri
  elsif $config["gadgets"][appname]
    uri = RelaxClient.for_gadgets(appname).uri
  else
    # nothing to do
  end

  if uri
    command = "couchapp push '#{appdir}' '#{uri}' -v"
    puts ">> [Update]"
    puts ">> #{command}"
    system(command)
    puts "<< [Done]"
  end
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
      push_app(appdir)       if dir =~ /^#{appdir}/
      reload_rack(proxydir)  if dir =~ /^#{proxydir}/
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

