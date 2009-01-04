require File.dirname(__FILE__) + '/../test_helper'

class MailerTest < ActiveSupport::TestCase

  def test_deliver_registration_confirmation
    @test_prepare = WjUser::LocalDB.prepare("test_prepare", "test_prepare@example.com")
    System::Mailer.deliver_registration_confirmation(@test_prepare, "http://example.com/")
  end

  def test_deliver_reset_password_confirmation
    wj_users(:yssk22).request_to_reset_password
    System::Mailer.deliver_reset_password_confirmation(wj_users(:yssk22), "http://example.com/")
  end
end
