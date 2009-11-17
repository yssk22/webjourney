require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), "../lib/security_token")
require File.join(File.dirname(__FILE__), "../../relax_client/lib/relax_client")
#
# clean up fixture/test data and reload from fixtures.
#
def reset_fixture
  containers_dir = File.join(File.dirname(__FILE__), "../../containers")
  containers = []
  # clean up fixtures for each database
  Dir.glob(File.join(containers_dir, "**/fixtures")) do |fdir|
    container_name = fdir.split("/")[-2]
    containers << container_name
    # Delete old fixtures
    db = RelaxClient.for_container(container_name)
    db.delete_fixtures
  end

  # insert fixtures for each container
  containers.each do |container_name|
    db = RelaxClient.for_container(container_name)
    files = Dir.glob(File.join(containers_dir, container_name, "fixtures/**/*.test.json"))
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

