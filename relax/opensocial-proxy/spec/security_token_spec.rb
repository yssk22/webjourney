require 'rubygems'
require File.join(File.dirname(__FILE__), "../lib/security_token")

# token example
RAW_TOKEN = "o=owner&v=viewer&a=app&d=domain&u=url&m=module&t=1"

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
