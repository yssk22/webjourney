require 'rubygems'
require 'rack'
require File.join(File.dirname(__FILE__), "../spec_helper")
require File.join(File.dirname(__FILE__), "../../lib/service/appdata")

#
# Fixtures are defined in
#  - relax/apps/opensocial/fixtures/people.test.json
#  - relax/apps/opensocial/fixtures/activities.test.json
#

# tokens including correct app_id
yssk22  = security_token("example.org:yssk22")
joe_doe = security_token("example.org:joe-doe")
john    = security_token("example.org:john")

# tokens including invalid app_id
yssk22_inv = security_token("example.org:yssk22", :app_id => "invalid")

describe Service::Appdata, "when fetching @self app data" do
  it "should return app data for the viewer" do
    result = Service::Appdata.get({ "userId" => "@me", "groupId" => "@self"}, yssk22)
    result.keys.length.should == 2
    result.should == { "key1" => "value1", "key2" => "value2" }

    result = Service::Appdata.get({ "userId" => "@me", "groupId" => "@self"}, joe_doe)
    result.keys.length.should == 0
  end

  it "should return app data for the specified user" do
    result = Service::Appdata.get({ "userId" => "example.org:yssk22", "groupId" => "@self"}, joe_doe)
    result.keys.length.should == 2
    result.should == { "key1" => "value1", "key2" => "value2" }
  end

  it "should return filtered app data for the specified user" do
    result = Service::Appdata.get({ "userId" => "example.org:yssk22", "groupId" => "@self",
                                    "keys" => ["key2"]}, joe_doe)
    result.keys.length.should == 1
    result.should == { "key2" => "value2" }
  end
end
