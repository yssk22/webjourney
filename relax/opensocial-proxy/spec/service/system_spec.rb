require 'rubygems'
require 'rack'
require File.join(File.dirname(__FILE__), "../../lib/service/system")

describe Service::System, "when proxied unsupported methods" do
  it "should raise 'not supported'" do
    Proc.new() {
      Service::System.apply("foo", "bar", {}, nil, nil)
    }.should raise_error(Service::NotSupportedError)
  end
end

describe Service::System, "list_methods" do
  before do
    @params, @req, @token = {}, nil, nil
    @result = Service::System.list_methods(@params, @req, @token)
  end

  it "should return an array" do
    @result.is_a?(Array).should be_true
  end

  it "should include system.listMethods" do
    @result.should include("system.listMethods")
  end

  it "should return the same results" do
    proxied_result = Service::System.apply("system", "listMethods", @params, @req, @token)
    @result.should be_eql(proxied_result)
  end
end

describe Service::System, "method_signatures" do
  it "should raise LazyImplentationError" do
    lambda { Service::System.method_signatures({}, nil, nil)}.should raise_error(Service::LazyImplementationError)
  end
end

describe Service::System, "method_help" do
  it "should raise LazyImplentationError" do
    lambda { Service::System.method_help({}, nil, nil)}.should raise_error(Service::LazyImplementationError)
  end
end
