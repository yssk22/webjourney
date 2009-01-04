require File.join(File.dirname(__FILE__), "../test_helper")

class WjComponentPageTest < ActiveSupport::TestCase
  def test_get
    assert_not_nil WjComponentPage.get("test", "component_page")
  end

  def test_controller
    page = WjComponentPage.get("test", "component_page")
    assert_equal "test/component_page", page.controller
  end

  def test_controller_fullname
    page = WjComponentPage.get("test", "component_page")
    assert_equal "test/component_page_controller", page.controller_fullname
  end

  def test_controller_class
    page = WjComponentPage.get("test", "component_page")
    assert_equal Test::ComponentPageController, page.controller_class
  end

  def test_accessible?
    page = WjComponentPage.get("test", "secure_component_page")
    assert_true page.accessible?(WjUser::BuiltIn::Administrator.me)
    assert_true page.accessible?(wj_users(:yssk22))
    assert_false page.accessible?(wj_users(:ma))
    assert_false page.accessible?(WjUser::BuiltIn::Anonymous.me)
  end

end
