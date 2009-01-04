require File.join(File.dirname(__FILE__), "../test_helper")
require File.join(File.dirname(__FILE__), "../functional_helper")

class ComponentPageControllerTest < ActiveSupport::TestCase
  def setup
    @controller = Test::ComponentPageController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response 200
  end
end
