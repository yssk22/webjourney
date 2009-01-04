require File.join(File.dirname(__FILE__), "../../test_helper")

class WjUser::BuiltInTest < ActiveSupport::TestCase
  def test_administrator
    administrator = WjUser::BuiltIn::Administrator.me
    assert_not_nil administrator
    assert_raise(WebJourney::AssertionFailedError) do
      administrator.destroy
    end
    assert_true administrator.authenticate(:password => "password")
    assert_false administrator.authenticate(:password => "invalid")
  end

  def test_anonymous
    anonymous = WjUser::BuiltIn::Anonymous.me
    assert_not_nil anonymous
    assert_raise(WebJourney::AssertionFailedError) do
      anonymous.destroy
    end
  end
end
