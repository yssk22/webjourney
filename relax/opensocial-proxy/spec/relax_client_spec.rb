require 'rubygems'
require 'rack'
require File.join(File.dirname(__FILE__), "../lib/relax_client")


describe RelaxClient, "get info" do
  before do
    @webjourney = RelaxClient.new("webjourney")
    @opensocial = RelaxClient.new("opensocial")
  end

  it "should returns db information" do
    info = @webjourney.info
    info["db_name"].should == "webjourney-default"
  end
end
