require File.join(File.dirname(__FILE__), '../test_helper')

class WjWidgetTest < ActiveSupport::TestCase
  def test_get
    assert_not_nil WjWidget.get("test", "widget1")
  end

  def test_build_new_instance
    top = WjPage.top
    widget = WjWidget.get("test", "widget1")
    instance = widget.build_new_instance(top, :location => "top", :index => 0)
    assert_not_nil instance
  end
end
