class RelaxClient # :nodoc
  #
  # Fixture function implementation for RelaxClient
  #
  module Fixture
    FIXTURE_MARKER   = "is_test_fixture"
    TEST_DATA_MARKER = "is_test_data"
    def delete_fixtures
      [FIXTURE_MARKER, TEST_DATA_MARKER].each do |marker|
        map = <<-EOS
function(doc){
  if(doc.#{marker}){
    emit(doc._id, {"_id" : doc._id, "_rev": doc._rev, "_deleted" : true})
  }
}
EOS
        # Get all marked documents with "_deleted".
        old = self.temp_view(map)["rows"].map { |row| row["value"] }
        # and post them to delete.
        if old.length > 0
          self.bulk_docs(old, :all_or_nothing => true)
        end
      end
    end

    def insert_fixtures(*files)
      result = import_from_file(*files) do |doc|
        doc[FIXTURE_MARKER] = true
        doc
      end
      result
    end

    def import_from_file(*files)
      docs = []
      files.each do |file|
        bulk = JSON.parse(ERB.new(File.read(file)).result)
        raise "Fixture #{file} is not an Array document. Please check the file." unless bulk.is_a?(Array)
        docs = docs + bulk.map { |doc|
          if block_given?
            yield doc
          else
            doc
          end
        }
      end
      docs.each do |r|
        r = { "id" => r["_id"], "rev" => r["_rev"] }
      end
      result = self.bulk_docs(docs, :all_or_nothing => false)
      result
    end
  end
end
