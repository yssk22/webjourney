class CouchFixture
  def self.load(basedir = File.join(RAILS_ROOT, "test/fixtures/couchdb/"))
    Dir.glob("#{basedir}/**/*.yml") do |f|
      # resolve class
      file = f.gsub(/^#{basedir}\//, '').gsub(/\.yml$/, '')
      klass = file.singularize.camelize.constantize
      # reset a database
      uri = klass.database
      Net::HTTP.start(uri.host, uri.port) { |http|
        http.delete(uri.path)
        http.put(uri.path, nil)
      }
      # load yaml file
      content = YAML.load(ERB.new(File.read(f)).result)
      if content
        content.each do |key, value|
          value.symbolize_keys!
          value[:_id] = key unless value[:_id]
          obj = klass.find(value[:_id]) rescue nil
          obj.destroy if obj
          obj = klass.new(value)
          obj.save!
        end
      end
    end
  end
end
