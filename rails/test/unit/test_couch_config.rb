require File.dirname(__FILE__) + '/../test_helper'

class CouchConfigTest < Test::Unit::TestCase
  def test_database_uri_for
    assert "http://localhost:5984/webjourney_test_system", CouchConfig.database_uri_for(:db => :system)
    assert "http://localhost:5984/webjourney_test_system", CouchConfig.database_uri_for
    # failure case for the configuration not defined
    assert_raise(NoMethodError) { CouchConfig.database_uri_for(:db  => "not_defined") }
    assert_raise(NoMethodError) { CouchConfig.database_uri_for(:env => "not_defined") }
  end
end
