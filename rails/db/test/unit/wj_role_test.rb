require File.join(File.dirname(__FILE__), '../test_helper')

class WjRoleTest < ActiveSupport::TestCase
  def test_update_default_roles
    WjRole.update_default_roles([wj_roles(:administrator),
                                wj_roles(:user),
                                wj_roles(:committer)])
    assert_true wj_roles(:administrator).reload.is_default
    assert_true wj_roles(:user).reload.is_default
    assert_true wj_roles(:committer).reload.is_default

    WjRole.update_default_roles([])
    assert_false wj_roles(:administrator).reload.is_default
    assert_false wj_roles(:user).reload.is_default
    assert_false wj_roles(:committer).reload.is_default

    WjRole.update_default_roles([wj_roles(:user)])
    assert_false wj_roles(:administrator).reload.is_default
    assert_true  wj_roles(:user).reload.is_default
    assert_false wj_roles(:committer).reload.is_default

  end
end
