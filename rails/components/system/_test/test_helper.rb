require File.join(File.dirname(__FILE__), "../../../test/test_helper")

directory = File.basename(File.expand_path(File.join(File.dirname(__FILE__), "..")))

pkg = WebJourney::Component::Package.new(directory)
pkg.set_output(nil)
pkg.install(false)

