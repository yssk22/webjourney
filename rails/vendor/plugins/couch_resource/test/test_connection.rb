require 'test/unit'
require File.join(File.dirname(__FILE__), "../lib/couch_resource/connection")

TEST_DB_PATH  = "/couch_resource_connection_test"

class TestStruct < Test::Unit::TestCase
  def setup
    @connection = CouchResource::Connection.new("http://localhost:5984")
  end

  def test_get
    res = @connection.get("/")
    assert_equal 200, res.code.to_i
  end

  def test_put_post_and_delete
    res = @connection.put(TEST_DB_PATH)
    assert_equal 201, res.code.to_i
    res = @connection.post(TEST_DB_PATH, "{}")
    assert_equal 201, res.code.to_i
    res = @connection.delete(TEST_DB_PATH)
    assert_equal 200, res.code.to_i
  end

  def test_put_and_delete
    res = @connection.put(TEST_DB_PATH)
    assert_equal 201, res.code.to_i
    res = @connection.delete(TEST_DB_PATH)
    assert_equal 200, res.code.to_i
  end
end
