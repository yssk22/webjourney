#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# Copyright 2010 Yohei Sasaki <yssk22@gmail.com>
#
# This software is licensed as described in the file LICENSE, which
# you should have received as part of this distribution.
#
# This script monitors couchapp directory and pushes it automatically when changed.
# This is available on RubyCocoa / OSX only (OSX's FSEvent API is used throught RubyCocoa)
#
require 'pathname'
require 'osx/foundation'
OSX.require_framework '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework'
include OSX

UPDATER = File.join(File.dirname(__FILE__), "update.py")

appdirs = Dir.glob(File.join(File.dirname(__FILE__), "../container/*")).
  select { |dir| File.directory?(dir) }.
  map    { |dir| Pathname.new(dir).realpath.to_s}

def push_app(appdir)
  name = appdir.split("/").last
  cmd = "python #{UPDATER} -c #{name}"
  puts cmd
  system(cmd)
end

file_updated = lambda {  |stream, ctx, numEvents, paths, marks, eventIDs|
  paths.regard_as('*')
  numEvents.times do |n|
    dir = paths[n]
    appdirs.each do |appdir|
      push_app(appdir) if dir =~ /^#{appdir}/
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
puts appdirs

begin
  CFRunLoopRun()
rescue Interrupt
  FSEventStreamStop(stream)
  FSEventStreamInvalidate(stream)
  FSEventStreamRelease(stream)
end

