require 'rubygems'
require 'rack'
require File.join(File.dirname(__FILE__), "../../lib/security_token")
require File.join(File.dirname(__FILE__), "../../lib/service/people")

#
# Fixtures are defined in
#  - relax/apps/opensocial/fixtures/people.test.json
#  - relax/apps/opensocial/fixtures/groups.test.json
#

def security_token(viewer_id, owner_id=nil)
  owner_id ||= viewer_id
  SecurityToken.new(viewer_id, owner_id,  "app1", "example.org", "http://example.org/app.xml", "module1", 0)
end

yssk22  = security_token("example.org:yssk22")
joe_doe = security_token("example.org:joe-doe")
john    = security_token("example.org:john")

describe Service::People, "normalize arguments" do
  it "should returns an Array when userId is an array." do
    result = Service::People.get({"userId" => ["@me"]}, yssk22)
    result.is_a?(Array).should be_true
  end

  it "should returns an Hash when userId is an array." do
    result = Service::People.get({"userId" => "@me"}, yssk22)
    result.is_a?(Hash).should be_true
  end

  it "should return an Hash when groupId is not @self." do
    result = Service::People.get({"userId" => "@me", "groupId" => "@friends"}, yssk22)
    result.is_a?(Array).should be_true
  end

end

describe Service::People, "when fetching @self." do
  it "should return a person object for the viewer." do
    result = Service::People.get({"userId" => "@me", "groupId" => "@self"}, yssk22)
    result["id"].should == yssk22.viewer_id
  end
end

describe Service::People, "when fetching @friends." do
  it "should return yssk22's list of friends" do
    result = Service::People.get({"userId" => "@me", "groupId" => "@friends"}, yssk22)
    result.is_a?(Array).should be_true

    # Data expectation.
    result.length.should == 2
    result.map { |r| r["id"] }.include?("example.org:joe-doe")
    result.map { |r| r["id"] }.include?("example.org:john")
  end
end

describe Service::People, "when fetching the specified userId" do
  it "should return the person object of example.org:yssk22" do
    result = Service::People.get({"userId" => "example.org:yssk22"}, john)
    result["id"].should == yssk22.viewer_id
  end

  it "should return yssk22's list of friends" do
    result = Service::People.get({"userId" => "example.org:yssk22", "groupId" => "@friends"}, john)

    result.length.should == 2
    result.map { |r| r["id"] }.include?("example.org:joe-doe")
    result.map { |r| r["id"] }.include?("example.org:john")
  end

  it "should return the person object of example.org:yssk22" do
  end

end

describe Service::People, "when fetching the specified groupId" do
  it "should return john's list of 'blocks'." do
    result = Service::People.get({"userId" => "@me", "groupId" => "blocks"}, john)
    result.length.should == 1
    result.map { |r| r["id"] }.include?("example.org:yssk22")
  end

  it "should return an empty array." do
    result = Service::People.get({"userId" => "@me", "groupId" => "foobar"}, john)
    result.length.should == 0
  end
end
