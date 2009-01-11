require 'test/unit'
require File.join(File.dirname(__FILE__), "../lib/couch_resource/connection")

TEST_DB_PATH  = "/couch_resource_connection_test"

class TestStruct < Test::Unit::TestCase
  def setup
    @connection = CouchResource::Connection.new("http://localhost:5984")
    begin
      res = @connection.put(TEST_DB_PATH)
    rescue CouchResource::ResourceConflict => e
      @connection.delete(TEST_DB_PATH)
      retry
    end
  end

  def test_get
    res = @connection.get("/")
    assert_not_nil   res[:couchdb]
    assert_equal "Welcome", res[:couchdb]
  end

  def test_normalize_hash
    res = @connection.post(TEST_DB_PATH, {
                             :a => {:b => { :c => [1,2,3]}}
                           }.to_json)
    assert_not_nil res[:id]
    id = res[:id]
    res = @connection.get(File.join(TEST_DB_PATH, id))
    assert_not_nil res[:_id]
    assert_not_nil res[:a]
    assert_not_nil res[:a][:b]
    assert_not_nil res[:a][:b][:c]
    assert_not_nil res["_id"]
    assert_not_nil res["a"]
    assert_not_nil res["a"]["b"]
    assert_not_nil res["a"]["b"]["c"]
  end
end
