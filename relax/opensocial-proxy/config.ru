require 'rubygems'
require 'json'
require File.join(File.dirname(__FILE__), 'lib/service/system')

# dispatch the rpc request
def dispatch(rpc, req)
  service, method = rpc["method"].split(".")
  result = Service::System.apply(service, method, rpc["params"], req)
  # TODO
  #   Currently shindig implementation required 'data' field, not 'result' field.
  #   This should be changed.
  {
    "id"     => rpc["id"],
    "data"   => result
  }
end

# JSON RPC endpoint
map "/rpc" do
  run proc { |env|
    req = Rack::Request.new(env)
    begin
      if req.post?
        json = JSON.parse(req.body.read)
        if json.is_a?(Array)
          [200,
           {'Content-Type'=>'application/json'},
           json.map { |rpc|
             dispatch(rpc, req)
           }.to_json
          ]
        else
          [200,
           {'Content-Type'=>'application/json'},
           dispatch(json, req).to_json
          ]
        end
      else # not a post request.
        [405,
         {'Content-Type'=>'application/json'},
         nil]
      end
    rescue => e
      [500,
       {'Content-Type'=>'application/json'},
       {"error" => e.message, "trace" => e.backtrace}.to_json]
    end
  }
end

