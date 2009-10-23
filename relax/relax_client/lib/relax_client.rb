require 'rubygems'
require 'restclient'
require 'json'
require 'cgi'
require 'erb'

require File.join(File.dirname(__FILE__), "./fixture")

#
# This class provide the features to access the CouchDB behind the opensocial proxy,
# especially used for accessing the relax applications implemented in relax/apps directory.
#
class RelaxClient
  include Fixture
  default_path = File.join(File.dirname(__FILE__), "../../../config/webjourney.json")
  local_path   = File.join(File.dirname(__FILE__), "../../../config/webjourney.local.json")
  @@config = JSON(File.read(default_path))
  @@config.update(JSON(File.read(local_path))) if File.exist?(local_path)

  attr_reader :uri

  def self.config
    @@config
  end

  #
  # Returns a new client instasnce for the specified container.
  #
  def self.for_container(name)
    self.new(name, true)
  end

  #
  # Returns a new client instasnce for the specified application.
  #
  def self.for_app(name)
    self.new(name, false)
  end

  #
  # Constructor
  #
  #  - <tt>app_name</tt> : one of the CouchApp application in the relax/apps directory.
  #
  def initialize(app_name, container_app = false)
    key = "apps"
    key = "containers" if container_app
    @uri      = @@config[key][app_name]
    @app_name = app_name
  end

  #
  # Get the database information
  #
  # See "Database Information" section at http://wiki.apache.org/couchdb/HTTP_database_API
  #
  def info()
    uri = build_uri()
    JSON.parse(RestClient.get(uri))
  end

  #
  # Return true when the database exists, othewise false.
  #
  def exist?
    begin
      uri = build_uri()
      JSON.parse(RestClient.get(uri))
      true
    rescue
      false
    end
  end

  #
  # Create the database
  #
  def create
    uri = build_uri()
    JSON.parse(RestClient.put(uri, ''))
  end

  #
  # Drop the database
  #
  def drop
    uri = build_uri()
    JSON.parse(RestClient.delete(uri))
  end

  #
  # Save the documents using _bulk_docs API
  #
  def bulk_docs(docs, option = {})
    uri  = build_uri("_bulk_docs")
    body = {
      "docs" => docs,
    }
    body["all_or_nothing"] = true if option[:all_or_nothing]

    JSON.parse(RestClient.post(uri,
                               body.to_json, :content_type => "application/json"))
  end

  #
  # Get the design document
  #
  def design(options = {})
    load("_design/#{@app_name}", options)
  end

  #
  #  Get the specified document from the database
  #
  def load(doc_id, options = {})
    uri = build_uri(doc_id, options)
    JSON.parse(RestClient.get(uri))
  end

  #
  # Save the specified document to the database
  #
  def save(doc)
    uri    = nil
    method = nil
    if doc["_id"]
      # PUT /{db}/{doc_id}
      method = :put
      uri    = build_uri(doc["_id"])
    else
      # POST /{db}
      method = :post
      uri = build_uri()
    end

    # TODO need to handle request failures.
    result = JSON.parse(RestClient.send(method, uri, doc.to_json, :content_type => "application/json"))
    doc.dup.update({ "_id" => result["id"], "_rev" => result["rev"]})
  end


  # Fetch the application specific view result.
  def view(viewname, options = {})
    keys = options.delete(:keys)
    uri = build_uri( "_design", @app_name, "_view", viewname, options)
    if keys
      JSON.parse(RestClient.post(uri, {:keys => keys }.to_json, :content_type => "application/json"))
    else
      JSON.parse(RestClient.get(uri))
    end
  end

  # Fetch the document with _all_docs API
  def all_docs(options = {})
    uri = build_uri("_all_docs", options)
    keys = options.delete(:keys)
    if keys
      JSON.parse(RestClient.post(uri, {:keys => keys }.to_json, :content_type => "application/json"))
    else
      JSON.parse(RestClient.get(uri))
    end
  end

  def temp_view(map, reduce = nil, options = {})
    uri = build_uri("_temp_view", options)
    doc = {:map => map}
    doc[:reduce] = reduce unless reduce
    JSON.parse(RestClient.post(uri, doc.to_json, :content_type => "application/json"))
  end

  private
  def build_uri(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    uri = File.join(*[@uri] + args.map{|a| CGI.escape(a)})
    if options.keys.length == 0
      uri
    else
      query = options.map { |k,v|
        case k.to_sym
        when :key, :startkey, :endkey
          "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_json)}"
        else
          "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"
        end
      }.join("&")
      "#{uri}?#{query}"
    end
  end
end
