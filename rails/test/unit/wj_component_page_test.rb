require File.join(File.dirname(__FILE__), '../test_helper')

#
# The fixture data is shared with the definition files
# stored in RAILS_ROOT/components/{component}/_db/define/*.yml
#

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
