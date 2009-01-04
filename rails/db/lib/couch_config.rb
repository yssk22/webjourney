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
