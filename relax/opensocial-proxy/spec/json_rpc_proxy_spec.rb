require 'rubygems'
require 'rack/test'
require File.join(File.dirname(__FILE__), '../lib/json_rpc_proxy')

include Rack::Test::Methods
def app
  JsonRpcProxy.new
end

ENDPOINT = "/rpc"

describe JsonRpcProxy, "when receiging valid request with st token" do
  before do
    @rpc = {
      "id" => "test",
      "method" => "people.get",
      "params" => { "p1" => "v1" }
    }
    mock_token = mock("token")
    SecurityToken.should_receive(:from_request).with(anything()).and_return(mock_token)
    Service::System.should_receive(:apply).
      with("people", "get", {"p1" => "v1"}, mock_token, anything()).
      and_return({"foo" => "bar"})
  end

  it "should response 200 ok" do
    post ENDPOINT, @rpc.to_json
    last_response.status.should == 200
    JSON.parse(last_response.body)["id"].should == @rpc["id"]
    JSON.parse(last_response.body)["data"].should == {"foo" => "bar"}
  end
end

describe JsonRpcProxy, "when the HTTP method is not POST" do
  it "should response 405 error" do
    get ENDPOINT
    last_response.status.should == 405
  end
end

describe JsonRpcProxy, "when the invalid json is post" do
  it "should response 400 error with a error message" do
    post ENDPOINT, "invalid json"
    last_response.status.should == 400
    JSON(last_response.body)["error"].should_not be_nil
  end
end

describe JsonRpcProxy, "when one of parameters is missing in the request" do
  it "should response 400 error with a error message." do
    post ENDPOINT, { }.to_json
    last_response.status.should == 400
    JSON(last_response.body)["error"].should_not be_nil

    post ENDPOINT, [{}].to_json
    last_response.status.should == 400
    JSON(last_response.body)["error"].should_not be_nil
  end
end

describe JsonRpcProxy, "when an uncaught exception detected" do
  before do
    @rpc = {
      "id" => "test",
      "method" => "people.get",
      "params" => { "p1" => "v1" }
    }
    Service::System.should_receive(:apply).and_raise("unknown error")
  end

  it "should response 500 error with a error message." do
    post ENDPOINT, @rpc.to_json
    last_response.status.should == 500
    JSON(last_response.body)["error"].should_not be_nil
  end
end


