require File.dirname(__FILE__) + "/../test_helper"
class WjMailerTest < Test::Unit::TestCase
  def setup
  end

  def test_mail
    WjMailer.deliver_test_mail("yssk22@dev.local")
  end
end
