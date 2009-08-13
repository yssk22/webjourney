require 'rubygems'
require 'json'
require File.join(File.dirname(__FILE__), 'lib/json_rpc_proxy')

map "/rpc" do
  run JsonRpcProxy.new
end

