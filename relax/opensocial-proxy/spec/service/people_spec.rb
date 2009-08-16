require 'rubygems'
require File.join(File.dirname(__FILE__), "../spec_helper")
require File.join(File.dirname(__FILE__), "../../lib/service/people")

#
# Fixtures are defined in
#  - relax/apps/opensocial/fixtures/people.test.json
#  - relax/apps/opensocial/fixtures/relationships.test.json
#
reset_fixtures

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

#
# Spec : people.get
#
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
    result.map { |r| r["id"] }.include?("example.org:joe-doe").should be_true
    result.map { |r| r["id"] }.include?("example.org:john").should be_true
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
    result.map { |r| r["id"] }.include?("example.org:joe-doe").should be_true
    result.map { |r| r["id"] }.include?("example.org:john").should be_true
  end
end

describe Service::People, "when fetching the specified groupId" do
  it "should return john's list of 'blocks'." do
    result = Service::People.get({"userId" => "@me", "groupId" => "blocks"}, john)
    result.length.should == 1
    result.map { |r| r["id"] }.include?("example.org:yssk22").should be_true
  end

  it "should return an empty array." do
    result = Service::People.get({"userId" => "@me", "groupId" => "foobar"}, john)
    result.length.should == 0
  end
end

#
# Spec : people.create
#
describe Service::People, "when creating the specified user" do
  it "should raise LazyImplementationError" do
    lambda {
      Service::People.create({}, yssk22)
    }.should raise_error(Service::LazyImplementationError)
  end
end

#
# Spec : people.update
#
describe Service::People, "when updating the specified user" do
  it "should raise ArgumentError if userId is not @me" do
    lambda {
      Service::People.update({"userId" => "foo"})
    }.should raise_error(ArgumentError)
  end

  it "should raise ArgumentError if groupId is not @self" do
    lambda {
      Service::People.update({"userId" => "@me", "groupId" => "@friends"})
    }.should raise_error(ArgumentError)
  end

  it "should raise ArgumentError if person is not specified" do
    lambda {
      Service::People.update({"userId" => "@me", "groupId" => "@self"})
    }.should raise_error(ArgumentError)
  end

  it "should return the updated person object" do
    old_doc = Service::People.get({}, yssk22)
    old_doc["type"].should == "Person"
    old_doc["displayName"]["formatted"].should == "yssk22"
    new_doc = Service::People.update({
                                       "person" => {
                                         # update yssk22 => 'Yohei Sasaki'
                                         "displayName" => { "formatted" => "Yohei Sasaki"}
                                       }
                                     },yssk22)
    new_doc["displayName"]["formatted"].should == "Yohei Sasaki"
    new_doc["_id"].should      == old_doc["_id"]
    new_doc["type"].should     == old_doc["type"]
    new_doc["_rev"].should_not == old_doc["_rev"]

    reloaded = Service::People.get({}, yssk22)
    reloaded["displayName"]["formatted"].should == "Yohei Sasaki"
  end

end