require 'rubygems'
require 'rack'
require File.join(File.dirname(__FILE__), "../spec_helper")
require File.join(File.dirname(__FILE__), "../../lib/service/activities")

#
# Fixtures are defined in
#  - relax/apps/opensocial/fixtures/people.test.json
#  - relax/apps/opensocial/fixtures/activities.test.json
#
reset_fixtures

# tokens including correct app_id
yssk22  = security_token("example.org:yssk22")
joe_doe = security_token("example.org:joe-doe")
john    = security_token("example.org:john")

# tokens including invalid app_id
yssk22_inv = security_token("example.org:yssk22", :app_id => "invalid")

describe Service::Activities, "when fetching @self activities" do
  it "should return activities for the viewer" do
    result = Service::Activities.get({"userId" => "@me", "groupId" => "@self"}, yssk22)
    result.length.should == 2
    result.map { |r| r["id"] }.include?("test_activity_1").should be_true
    result.map { |r| r["id"] }.include?("test_activity_2").should be_true

    result = Service::Activities.get({"userId" => "@me", "groupId" => "@self"}, joe_doe)
    result.length == 0
  end

  it "should return activities for the specified user" do
    result = Service::Activities.get({"userId" => "example.org:yssk22", "groupId" => "@self"}, joe_doe)
    result.length.should == 2
    result.map { |r| r["id"] }.include?("test_activity_1").should be_true
    result.map { |r| r["id"] }.include?("test_activity_2").should be_true
  end

  it "should return filtered activities with activityIds arguments" do
    result = Service::Activities.get({
                                       "userId" => "example.org:yssk22",
                                       "groupId" => "@self",
                                       "activityIds" => ["test_activity_2"]
                                     }, joe_doe)
    result.length.should == 1
    result.map { |r| r["id"] }.include?("test_activity_2").should be_true
  end
end


describe Service::Activities, "when fetching with the token including the invalid app_id" do
  it "should return the empty" do
    result = Service::Activities.get({"userId" => "@me", "groupId" => "@self"}, yssk22_inv)
    result.length.should == 0
  end
end
