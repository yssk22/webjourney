#
# = Experimental loader for CouchDB fixture data
#
# CouchDB fixture is an experimental module for Testing. Fixture data is stored in test/fixtures/couchdb/*.yml in YAML format.
# Some useful features in ActiveRecord fixture such as transactional data cannot not supported in CouchDB.
#
class CouchFixture
  #
  # Load all fixtures in the <tt>basedir</tt>. If the fixture data is already stored in database, it'll be destroyed and newly created.
  #
  def self.load(basedir = File.join(RAILS_ROOT, "test/fixtures/couchdb/"))
    # collecting database and yaml dataset pairs
    datasets = {}
    Dir.glob("#{basedir}/**/*.yml") do |f|
      # resolve class
      file = f.gsub(/^#{basedir}\//, '').gsub(/\.yml$/, '')
      klass = file.singularize.camelize.constantize
      # reset a database
      uri = klass.database
      datasets[uri] ||= []
      content = YAML.load(ERB.new(File.read(f)).result)
      datasets[uri] << [klass, content]
    end

    datasets.each do |uri, classes|
      RAILS_DEFAULT_LOGGER.debug "CouchFixture : reset database (#{uri})."
      Net::HTTP.start(uri.host, uri.port) { |http|
        http.delete(uri.path)
        http.put(uri.path, nil)
      }
      RAILS_DEFAULT_LOGGER.debug "CouchFixture : push the datasets (#{uri})."
      classes.each do |klass, content|
        klass.write_inheritable_attribute(:design_revision_checked, false)
        # load yaml file
        if content
          content.each do |key, value|
            value.symbolize_keys!
            value[:_id] = key unless value[:_id]
            # obj = klass.find(value[:_id]) rescue nil
            # obj.destroy if obj
            obj = klass.new(value)
            begin
              obj.save!
            rescue CouchResource::PreconditionFailed
              raise "Cannot load fixture with #{key} on #{uri} (duplicated key?)"
            end
          end
        end
      end
    end
  end
end
