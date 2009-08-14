require 'rubygems'
require 'rack'
require File.join(File.dirname(__FILE__), "../spec_helper")
require File.join(File.dirname(__FILE__), "../../lib/service/activities")

#
# Fixtures are defined in
#  - relax/apps/opensocial/fixtures/people.test.json
#  - relax/apps/opensocial/fixtures/activities.test.json
#

# tokens including correct app_id
yssk22  = security_token("example.org:yssk22")
joe_doe = security_token("example.org:joe-doe")
john    = security_token("example.org:john")

describe Service::Util, "when normalizing user ids" do
  it 'should return an array wheen ids is not an array' do
    ids = Service::Util.normalize_user_ids("@me", yssk22)
    ids.is_a?(Array).should be_true
  end

  it 'should return viewer_id of the token if matching @me' do
    ids = Service::Util.normalize_user_ids("@me", yssk22)
    ids.first.should == "example.org:yssk22"
  end

  it 'should return ids without any changes if not matching @me' do
    ids = Service::Util.normalize_user_ids(["a", "b", "@me"], yssk22)
    ids.length.should == 3
    ids.should == ["a", "b", "example.org:yssk22"]
  end

  it 'should raise ArgumentError when ids is an unknown placeholder.' do
    lambda { Service::Util.normalize_user_ids("@unknown", nil)}.should raise_error(ArgumentError)
  end
end

describe Service::Util, "when resolving user ids by group id" do
  it 'should raise ArgumentError when groupId is an unknown placeholder.' do
    lambda { Service::Util.resolve_user_ids_by_group_id(["a"], "@unknown", nil)}.should raise_error(ArgumentError)
  end
end

