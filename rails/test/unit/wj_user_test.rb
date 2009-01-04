require File.join(File.dirname(__FILE__), '../test_helper')

class WjUserTest < ActiveSupport::TestCase
  def test_list
    # starts_with
    # yssk22 and yssk22_openid should be matched
    result = WjUser.list({:starts_with => "y"})
    assert_equal 2, result.length
    # type
    result = WjUser.list({:class => WjUser::OpenId, :starts_with => "y"})
    assert_equal 1, result.length
    # status
    # destroyed_test_user should be matched
    result = WjUser.list({:starts_with => "d", :status => WjUser::Status[:destroyed]})
    assert_equal 1, result.length
    assert_equal "destroyed_test_user", result.first.login_name
  end

  def test_is_active?
    yssk22 = wj_users(:yssk22)
    assert_true yssk22.active?
    assert_true yssk22.is_active?
  end

  def test_has_roles?
    yssk22 = wj_users(:yssk22)
    assert_true yssk22.has_roles?
    assert_true yssk22.has_roles?(:user)
    assert_true yssk22.has_roles?(:user, :any => true)
    assert_true yssk22.has_roles?(:user, :committer)
    assert_true yssk22.has_roles?(:user, :committer, :any => true)
    # or condition
    assert_true yssk22.has_roles?(:user, :administrator, :any => true)
    # and conditions
    assert_false yssk22.has_roles?(:user, :administrator)
  end
end
