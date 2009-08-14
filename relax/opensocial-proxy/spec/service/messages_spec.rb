require 'rubygems'
require File.join(File.dirname(__FILE__), "../spec_helper")
require File.join(File.dirname(__FILE__), "../../lib/service/messages")

#
# Fixtures are defined in
#  - relax/apps/opensocial/fixtures/people.test.json
#
reset_fixtures
yssk22  = security_token("example.org:yssk22")
joe_doe = security_token("example.org:joe-doe")

describe Service::Messages, "sending a message" do
  it "should return nil even if the message successfully sent." do
    result = Service::Messages.send({ "message" => {
                                      TEST_DATA_MARKER => true,
                                      :title => "foo",
                                      :body => "bar",
                                      :recipients => [joe_doe.owner_id]
                                    }
                                  }, yssk22)
    result.should be_nil
  end
end

describe Service::Messages, "sending a nil message" do
  it "should raise ArgumentError" do
    lambda {
      result = Service::Messages.send({}, yssk22)
    }.should raise_error(ArgumentError)
  end
end
