require File.join(File.dirname(__FILE__), '../test_helper')

class WjComponentPageTest < ActiveSupport::TestCase
  def test_get
    assert_not_nil WjComponentPage.get("system", "login")
    assert_nil     WjComponentPage.get("not_installed", "not_found")
  end

  def test_dom_id
    login_page = WjComponentPage.get("system", "login")
    assert_equal 'cpm_body',     login_page.dom_id()
    assert_equal 'cpm_body_abc', login_page.dom_id("abc")
  end

  def test_shortcuts
    login_page = WjComponentPage.get("system", "login")
    assert_equal "system/login", login_page.controller
    assert_equal "system/login_controller", login_page.controller_fullname
    assert_equal System::LoginController,   login_page.controller_class
    assert_equal "/components/system/images/login.png", login_page.image_path
    assert_equal "/components/system/javascripts/login.js",  login_page.javascript_path
    assert_equal "/components/system/stylesheets/login.css", login_page.stylesheet_path
  end

  def test_accesssible?
    page = WjComponentPage.get("system", "login")
    assert_true page.accessible?(wj_users(:administrator))
    assert_true page.accessible?(wj_users(:yssk22))
    assert_true page.accessible?(wj_users(:anonymous))

    page = WjComponentPage.get("system", "my_account_page")
    assert_true  page.accessible?(wj_users(:administrator))
    assert_true  page.accessible?(wj_users(:yssk22))
    assert_false page.accessible?(wj_users(:anonymous))

    page = WjComponentPage.get("system", "site_configuration_pages")
    assert_true  page.accessible?(wj_users(:administrator))
    assert_false page.accessible?(wj_users(:yssk22))
    assert_false page.accessible?(wj_users(:anonymous))
  end

end
