require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), "../lib/security_token")
require File.join(File.dirname(__FILE__), "../../relax_client/lib/relax_client")

FIXTURE_MARKER   = "is_test_fixture"
TEST_DATA_MARKER = "is_test_data"

#
# clean up fixture/test data and reload from fixtures.
#
def reset_fixture
  apps_dir = File.join(File.dirname(__FILE__), "../../apps")
  apps = []
  # clean up fixtures for each database
  Dir.glob(File.join(apps_dir, "**/fixtures")) do |fdir|
    app_name = fdir.split("/")[-2]
    apps << app_name
    # Delete old fixtures
    db = RelaxClient.new(app_name)
    db.delete_fixtures
  end

  # insert fixtures for each app
  apps.each do |app_name|
    db = RelaxClient.new(app_name)
    docs = []
    files = Dir.glob(File.join(apps_dir, app_name, "fixtures/**/*.test.json"))
    db.insert_fixtures(*files)
  end
end
alias :reset_fixtures :reset_fixture

#
# Generate security token for spec test
#
def security_token(viewer_id, option = { })
  option = {
    :owner_id  => viewer_id,
    :app_id    => "test",
    :domain_id => "example.org",
    :app_url   => "http://example.org/test.xml",
    :module_id => "test",
    :time      => 0
  }.update(option)
  SecurityToken.new(viewer_id,
                    option[:owner_id],
                    option[:app_id],
                    option[:domain_id],
                    option[:app_url],
                    option[:module_id],
                    option[:time])
end

