require File.join(File.dirname(__FILE__), '../test_helper')

#
# The fixture data is shared with the definition files
# stored in RAILS_ROOT/components/{component}/_db/define/*.yml
#

class WjComponentTest < ActiveSupport::TestCase
  def test_component_menu_list
    list = WjComponent.component_menu_list(wj_users(:administrator))
    assert_equal 3, list.length
  end

  def test_widget_selection_list
    list = WjComponent.widget_selection_list(wj_users(:administrator))
    assert_equal 3, list.length
  end

  def test_get_accessible_pages_for
    system = WjComponent.find_by_directory_name("system")
    pages = system.get_accessible_pages_for(wj_users(:administrator))
    assert_equal 4, pages.length
    pages = system.get_accessible_pages_for(wj_users(:anonymous))
    assert_equal 1, pages.length
  end

  def test_get_available_widgets_for
    system = WjComponent.find_by_directory_name("system")
    pages = system.get_available_widgets_for(wj_users(:administrator))
    assert_equal 1, pages.length
    pages = system.get_available_widgets_for(wj_users(:anonymous))
    assert_equal 1, pages.length
  end
end
