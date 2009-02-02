#
# CouchDB Configuration Loader class
#
# = Configuration CouchDB Data Source in YAML
#
# Database configurations can be defined in Yaml format. WebJourney can support multiple CouchDB databases.
# There are two types of configuration YAML files in WebJourney.
#
# - site level configuration, located in RAILS_ROOT/config/couchdb.yml
# - component level configuration, located in RAILS_ROOT/components/{component_dir}/_config/couchdb.yml
#
# = YAML format
#
# The configuration format is almost the same as database.yml except that couchdb.yml requires <tt>db identifier</tt> for the multiple database support.
# The format is as follows::
#
#   {environement}:
#      {db_identifier}:
#         host : {couchdb hostname}
#         port : {couchdb port}
#         database : {couchdb database name}
#
# For example, WjPage objects are persisted in one CouchDB database and WjUserProfile objects in another. In this case,
# two databases are required so that the couchdb.yml (for <tt>development</tt> and <tt>production</tt>) is as follows::
#
#   development:
#     wj_user_profiles:
#         host: localhost
#         port: 5984
#         database: webjourney_dev_wj_profile
#     wj_pages:
#         host: localhost
#         port: 5984
#         database: webjourney_dev_wj_pages
#
#   production:
#     wj_user_profiles:
#         host: couch_site1
#         port: 5984
#         database: webjourney_dev_wj_profile
#     wj_pages:
#         host: couch_site2
#         port: 5984
#         database: webjourney_dev_wj_pages
#
# = Specify the database in CouchResource models
#
# CouchConfig class does only resolve a name to the couchdb database url by the <tt>database_uri_for</tt> method.
# On the other hand, it is required to specify a database in a CouchResource model class (by <tt>set_database</tt> method).
# So configruations loaded by CouchConfig and CouchResource classes are related as follows.
#
# At first, there are two couchdb.yml files. one is the site level configuration file.
#
#   # RAILS_ROOT/config/couchdb.yml
#   development:
#     abc:
#         host: localhost
#         port: 5984
#         database: system_abc
#
# The other is the component level configuraiton.
#
#   # RAILS_ROOT/comopnents/my_component/config/couchdb.yml
#   development:
#     abc:
#         host: 192.168.1.10
#         port: 5984
#         database: my_component_abc
#
# == Using site level database (often used by the WebJounrney framework)
#
#   class MyDocumentModel < CouchResource::Base
#      # specify without the '/' separator.
#      set_database CouchConfig.database_uri_for(:db => "abc")
#
#   end
#
# In this case, CouchConfig loads the configuration from RAILS_ROOT/config/couchdb.yml so that
# MyDocumentModel objects are stored at <tt>#http://localhost:5984/system_abc</tt>.
#
# == Using component level database (often used by components)
#
#   class MyComponent::MyDocumentModel < CouchResource::Base
#      # specify with the '/' separator.
#      set_database CouchConfig.database_uri_for(:db => "my_component/abc")
#
#   end
#
# In this case, CouchConfig loads the configuration from RAILS_ROOT/component/my_component/_config/couchdb.yml so that
# MyComponent::MyDocumentModel objects are stored at <tt>#http://192.168.1.10:5984/my_component_abc</tt>.
#
#
class CouchConfig
  # Get the all configuration hash
  def self.get(component = nil)
    if component.blank?
      @@config ||= YAML.load(File.open(File.join(RAILS_ROOT, "config/couchdb.yml")))
    else
      @@component_config ||= {}
      @@component_config[component] ||= YAML.load(File.open(File.join(RAILS_ROOT, "components", component, "_config/couchdb.yml")))
    end
  end

  # Get the current configuration (specified to the database) by URI string
  def self.database_uri_for(option = {})
    env = (option[:env] || RAILS_ENV).to_s
    db  = (option[:db]  || :system).to_s

    component, dbname = db.split("/")

    # swap if db does not have any '/' separators.
    component, dbname = dbname, component    if dbname.blank?

    config = self.get(component)[env.to_s][dbname]

    # check each attributes
    scheme   = config["scheme"]   || "http"
    host     = config["host"]     || "localhost"
    port     = config["port"]     || 5984
    database = config["database"] || ("webjourney_#{RAILS_ENV}_#{dbname}")
    "#{scheme}://#{host}:#{port}/#{database}"
  end
end
