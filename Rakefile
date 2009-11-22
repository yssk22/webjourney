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
require File.join(File.dirname(__FILE__), "lib/relax_client")
require File.join(File.dirname(__FILE__), "tasks/methods")
require File.join(File.dirname(__FILE__), "tasks/all")
require File.join(File.dirname(__FILE__), "tasks/containers")
require File.join(File.dirname(__FILE__), "tasks/gadgets")
require File.join(File.dirname(__FILE__), "tasks/print")
require File.join(File.dirname(__FILE__), "tasks/couchdb")

#
# initialize constants from configuration
#
# HTTP_ROOT            = "http://#{RelaxClient.config["httpd"]["servername"]}"
# TOP_PAGE_PATH        = File.join(CONTAINER_TO_DB["webjourney"].split("/").last, "_design/webjourney/_show/page/pages:top")
IMPORT_TEST_FIXTURES = RelaxClient.config["misc"]["import_test_fixtures"]

# End of Task
# ****************************************************
# Belows are the utility method for tasks.
