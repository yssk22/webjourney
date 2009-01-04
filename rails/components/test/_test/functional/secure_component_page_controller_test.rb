require File.join(File.dirname(__FILE__), "../test_helper")
require File.join(File.dirname(__FILE__), "../functional_helper")

class SecureComponentPageControllerTest < ActiveSupport::TestCase
  def setup
    @controller = Test::SecureComponentPageController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response 401
    login(wj_users(:ma)) do
      get :index
      assert_response 403
    end
    login(wj_users(:yssk22)) do
      get :index
      assert_response 200
    end
  end
end
