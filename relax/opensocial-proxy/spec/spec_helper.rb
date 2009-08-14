require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), "../lib/security_token")
require File.join(File.dirname(__FILE__), "../lib/relax_client")

#
# Make fixtures reset on the specified timing.
# The argument should be :all or :each.
#
def use_fixture()
  Spec::Runner.configure do |config|
    config.before(:all) do
      reset_fixture
    end
  end
end

#
# Reset the database using fixtures.
#
def reset_fixture
  apps_dir = File.join(File.dirname(__FILE__), "../../apps")
  Dir.glob(File.join(apps_dir, "**/fixtures")) do |fdir|
    app_name = fdir.split("/")[-2]
    db = RelaxClient.new(app_name)

    db.drop if db.exist?
    db.create
    docs = []
    Dir.glob(File.join(fdir, "**/*.json")) do |file|
      bulk = JSON.parse(File.read(file))
      raise "Fixture #{file} is not an Array document. Please check the file." unless bulk.is_a?(Array)
      docs = docs + bulk
    end
    db.bulk_docs(docs, :all_or_nothing => true)
  end
end

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
