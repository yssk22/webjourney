require File.join(File.dirname(__FILE__), '../test_helper')

class WjWidgetTest < ActiveSupport::TestCase
  def test_get
    assert_not_nil WjWidget.get("sticky", "text")
    assert_nil     WjWidget.get("not_installed", "not_found")
  end

  def test_build_new_instance
    top = WjPage.top
    widget = WjWidget.get("sticky", "text")
    instance = widget.build_new_instance(top)
    assert_not_nil instance
  end

  def test_available_for?
    widget = WjWidget.get("sticky", "text")
    assert_true widget.available_for?(wj_users(:administrator))
  end

  def test_json_for_new_widget
    widget = WjWidget.get("sticky", "text")
    assert_equal({ :component => "sticky",
                   :widget    => "text",
                   :title     => "Sticky/Text"
    }.to_json, widget.json_for_new_widget)
  end
end
