require File.join(File.dirname(__FILE__), '../../test_helper')

class WjUser::LocalDBTest < ActiveSupport::TestCase
  def test_authenticate
    @yssk22 = wj_users(:yssk22)
    assert_true @yssk22.authenticate(:password => "password")
    assert_true @yssk22.authenticate(:password_hash => @yssk22.hash_password("password"))
    # confirm to update last_login_at
    last_login_at = @yssk22.last_login_at
    assert_true @yssk22.authenticate(:password => "password")
    assert_not_equal last_login_at, @yssk22.last_login_at
  end

  def test_prepare
    @test_prepare = WjUser::LocalDB.prepare("test_prepare", "test_prepare@example.org")
    assert_false @test_prepare.new_record?
    assert_equal WjUser::Status[:prepared], @test_prepare.status
    assert_equal 'register', @test_prepare.request_key
    assert_not_nil @test_prepare.request_passcode
  end

  def test_activate
    @test_activate = WjUser::LocalDB.prepare("test_activate", "test_activate@example.org")
    assert_false @test_activate.new_record?
    passcode = @test_activate.request_passcode
    assert_true @test_activate.activate(passcode, "passw0rd")
    assert_nil @test_activate.request_key
    assert_nil @test_activate.request_value
    assert_equal WjUser::Status[:active], @test_activate.status
  end

  def test_reset_password
    @yssk22 = wj_users(:yssk22)
    assert_true @yssk22.authenticate(:password => "password")
    assert_true @yssk22.prepare_to_reset_password
    new_password = @yssk22.request_value
    assert_true @yssk22.commit_to_reset_password(@yssk22.request_passcode)
    assert_true @yssk22.authenticate(:password => new_password)
    assert_false @yssk22.authenticate(:password => "password")
  end

end
