require File.join(File.dirname(__FILE__), '../test_helper')

class WjWidgetInstanceTest < ActiveSupport::TestCase
  def test_wj_page
    instance = WjWidgetInstance.find("welcome_to_webjourney")
    assert_equal "top", instance.wj_page.id
  end

  def test_wj_widget
    instance = WjWidgetInstance.find("welcome_to_webjourney")
    assert_equal "sticky", instance.wj_widget.wj_component.directory_name
    assert_equal "html", instance.wj_widget.controller_name
  end

  def test_image_path
    instance = WjWidgetInstance.find("welcome_to_webjourney")
    assert_equal instance.wj_widget.image_path, instance.image_path
  end

  def test_javascript_path
    instance = WjWidgetInstance.find("welcome_to_webjourney")
    assert_equal instance.wj_widget.javascript_path, instance.javascript_path
  end

  def test_stylesheet_path
    instance = WjWidgetInstance.find("welcome_to_webjourney")
    assert_equal instance.wj_widget.stylesheet_path, instance.stylesheet_path
  end

  def test_has_javascript?
    instance = WjWidgetInstance.find("welcome_to_webjourney")
    assert_false instance.has_javascript?
  end

  def test_has_stylesheet?
    instance = WjWidgetInstance.find("welcome_to_webjourney")
    assert_false instance.has_stylesheet?
  end
end
