require File.join(File.dirname(__FILE__), "../test_helper")

class TestHelperTest < ActiveSupport::TestCase
  def test_fixtures
    assert_not_nil wj_users(:yssk22)
  end

  def test_component_is_registered
    assert_not_nil WjComponent.find_by_directory_name("test")
    assert_not_nil WjComponentPage.find_by_controller_name("component_page_test")
  end
end
