require 'rubygems'
require File.join(File.dirname(__FILE__), "../lib/security_token")

# token example
RAW_TOKEN = "o=owner&v=viewer&a=app&d=domain&u=url&m=module&t=1"

describe SecurityToken, "when non-oauth request that has securiy token is passed" do
  before do
    @mock_req       = mock("mock_oauth_req", {
                             :params => {
                               "st" => RAW_TOKEN
                             }
                           })
    mock_oauth_req = mock("mock_oauth_req", {
                            :oauth_signature    => false,
                            :oauth_consumer_key => false
                          })
    OAuth::RequestProxy::RackRequest.should_receive(:new).with(@mock_req).and_return(mock_oauth_req)

    @st = SecurityToken.from_request(@mock_req)
  end

  it "should parse token from st parameter." do
    token = SecurityToken.from_string(@mock_req.params["st"])
    @st.should == token
  end
end

describe SecurityToken, "when no token request is passed" do
  before do
    @mock_req       = mock("mock_oauth_req", {
                             :params => {
                             }
                           })
    mock_oauth_req = mock("mock_oauth_req", {
                            :oauth_signature    => false,
                            :oauth_consumer_key => false
                          })
    OAuth::RequestProxy::RackRequest.should_receive(:new).with(@mock_req).and_return(mock_oauth_req)
  end

  it "should return the anonymous token" do
    @st = SecurityToken.from_request(@mock_req)
    @st.should == SecurityToken::ANONYMOUS
  end
end

describe SecurityToken, "equality" do
  it "should be true when each of properties is equal to that of others" do
    st1 = SecurityToken.new("viewer_id", "owerer_id", "app_id", "domain_id", "app_url", "module_id", 0)
    st2 = SecurityToken.new("viewer_id", "owerer_id", "app_id", "domain_id", "app_url", "module_id", 0)
    st1.should == st2
  end

  it "should be false when one of properties is not equal" do
    st1 = SecurityToken.new("viewer_id", "owerer_id", "app_id", "domain_id", "app_url", "module_id", 0)
    st2 = SecurityToken.new("viewer_id", "owerer_id", "app_id", "domain_id", "app_url", "module_id", 2)
    st1.should_not == st2
  end
end

describe SecurityToken, "when raw token string is passed" do
  before do
    @st = SecurityToken.from_string(RAW_TOKEN, false)
  end

  it "should have owner" do
    @st.owner_id.should == "owner"
  end

  it "should have viewer" do
    @st.viewer_id.should == "viewer"
  end

  it "should have app" do
    @st.app_id.should == "app"
  end

  it "should have domain" do
    @st.domain_id.should == "domain"
  end

  it "should have url" do
    @st.app_url.should == "url"
  end

  it "should have module" do
    @st.module_id.should == "module"
  end

  it "should have time" do
    @st.time.should == "1"
  end
end
