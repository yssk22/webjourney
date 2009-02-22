require File.join(File.dirname(__FILE__), "../test_helper")
require File.join(File.dirname(__FILE__), "../functional_helper")

class ComponentControllerTest < ActiveSupport::TestCase
  def setup
    @controller = Test::ComponentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response 200
  end

  def test_administrator_action
    get :administrator_action
    assert_response 401
    login(wj_users(:yssk22)) do
      get :administrator_action
      assert_response 403
    end
    login(WjUser::BuiltIn::Administrator.me) do
      get :administrator_action
      assert_response 200
    end
  end

  def test_committer_action
    get :committer_action
    assert_response 401
    login(wj_users(:ma)) do
      get :committer_action
      assert_response 403
    end
    login(wj_users(:yssk22)) do
      get :committer_action
      assert_response 200
    end
  end

end
