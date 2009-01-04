require File.dirname(__FILE__) + '/../../test_helper'

class OpenIdTest < ActiveSupport::TestCase

  def test_prepare
    user = WjUser::OpenId.prepare("http://a.b.c/x/y/z")
    assert_equal "z_y_x_a_b_c", user.login_name
    user = WjUser::OpenId.prepare("http://www.example.org/path/to/login_name")
    assert_equal "login_name_to", user.login_name
    user = WjUser::OpenId.prepare("http://www.example.org/path/to/~login_name")
    assert_equal "login_name_to", user.login_name
  end

  def test_get_suggest_login_name
    assert_equal "z_y_x_a_b_c", WjUser::OpenId.get_suggest_login_name("http://a.b.c/x/y/z")
    assert_equal "login_name_to", WjUser::OpenId.get_suggest_login_name("http://www.example.org/path/to/login_name")
    assert_equal "login_name_to", WjUser::OpenId.get_suggest_login_name("http://www.example.org/path/to/~login_name")
  end
end
