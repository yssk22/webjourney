module RakeUtil
  def create_couchdb_for_component(component)
    begin
      CouchConfig.get(component).each do |env, config|
        if env == RAILS_ENV
          config.each do |target, config2|
            create_db(env, File.join(component, target))
          end
        end
      end
    rescue Errno::ENOENT => e
      puts "[Skip] The database configuration (components/#{component}/_config/couchdb.yml) is not found)."
    end
  end

  def drop_couchdb_for_component(component)
    begin
      CouchConfig.get(component).each do |env, config|
        if env == RAILS_ENV
          config.each do |target, config2|
            drop_db(env, File.join(component, target))
          end
        end
      end
    rescue Errno::ENOENT => e
      puts "[Skip] The database configuration (components/#{component}/_config/couchdb.yml) is not found)."
    end
  end

  def install_components(*components)
    components.each do |component|
      pkg = WebJourney::Component::Package.new(component)
      pkg.install(false)
      create_couchdb_for_component(component)
    end
  end

end
