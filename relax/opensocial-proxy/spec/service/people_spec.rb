require 'rubygems'
require 'rack'
require File.join(File.dirname(__FILE__), "../../lib/security_token")
require File.join(File.dirname(__FILE__), "../../lib/service/people")

#
# Fixtures are defined in
#  - relax/apps/opensocial/fixtures/people.test.json
#  - relax/apps/opensocial/fixtures/groups.test.json
#

yssk22 = SecurityToken.new("example.org:yssk22", "example.org:yssk22", "app1", "example.org", "http://example.org/app.xml", "module1", 0)

describe Service::People, "normalize arguments" do
  it "should returns an Array when userId is an array." do
    result = Service::People.get({"userId" => ["@me"]}, yssk22)
    result.is_a?(Array).should be_true
  end

  it "should returns an Hash when userId is an array." do
    result = Service::People.get({"userId" => "@me"}, yssk22)
    result.is_a?(Hash).should be_true
  end
end

describe Service::People, "when passed userId placeholder, @me." do
end
