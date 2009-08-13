require 'rubygems'
require 'restclient'
require 'json'
require 'cgi'
#
# This class provide the features to access the CouchDB behind the opensocial proxy,
# especially used for accessing the relax applications implemented in relax/apps directory.
#
class RelaxClient
  env = ENV["WEBJOURNEY_ENV"] || "default"
  @@config = YAML.load(File.read(File.join(File.dirname(__FILE__), "../../../config/webjourney.yml")))[env]

  #
  # Constructor
  #
  #  - <tt>app_name</tt> : one of the CouchApp application in the relax/apps directory.
  #
  def initialize(app_name)
    @uri      = @@config["couchdb"][app_name]
    @app_name = app_name
  end

  #
  # Get the database information
  #
  # See "Database Information" section at http://wiki.apache.org/couchdb/HTTP_database_API
  #
  def info()
    uri = build_uri(@uri)
    JSON.parse(RestClient.get(uri))
  end

  #
  # Get the design document
  #
  def design(options = {})
    load("_design%2F#{@app_name}", options)
  end

  #
  #  Get the specified document from the database
  #
  def load(doc_id, options = {})
    uri = build_uri(@uri, options)
    JSON.parse(RestClient.get(uri))
  end

  # Fetch the application specific view result.
  def view(viewname, options = {})
    keys = options.delete(:keys)
    uri = build_uri(@uri, "_design", @app_name, "_view", viewname, options)
    if keys
      JSON.parse(RestClient.post(uri, {:keys => keys }.to_json, :content_type => "application/json"))
    else
      JSON.parse(RestClient.get(uri))
    end

  end

  private
  def build_uri(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    uri = File.join(*args)
    if options.keys.length == 0
      uri
    else
      query = options.map { |k,v|
        "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"
      }.join("&")
      "#{uri}?#{query}"
    end
  end

end
