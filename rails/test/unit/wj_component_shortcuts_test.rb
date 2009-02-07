require File.join(File.dirname(__FILE__), '../test_helper')

#
# The fixture data is shared with the definition files
# stored in RAILS_ROOT/components/{component}/_db/define/*.yml
#

class WjComponentShortcutsTest < ActiveSupport::TestCase
  def test_shortcuts
    login_page = WjComponentPage.get("system", "login")
    assert_equal "system/login", login_page.controller
    assert_equal "system/login_controller", login_page.controller_fullname
    assert_equal System::LoginController,   login_page.controller_class
    assert_equal "/components/system/images/login.png", login_page.image_path
    assert_equal "/components/system/javascripts/login.js",  login_page.javascript_path
    assert_equal "/components/system/stylesheets/login.css", login_page.stylesheet_path

    text_widget = WjWidget.get("sticky", "text")
    assert_equal "sticky/text", text_widget.controller
    assert_equal "sticky/text_controller", text_widget.controller_fullname
    assert_equal Sticky::TextController,   text_widget.controller_class
    assert_equal "/components/sticky/images/text.png", text_widget.image_path
    assert_equal "/components/sticky/javascripts/text.js",  text_widget.javascript_path
    assert_equal "/components/sticky/stylesheets/text.css", text_widget.stylesheet_path

  end
end
