require File.join(File.dirname(__FILE__), '../profile_helper')

class PagesControllerTest < ActionController::TestCase
  include RubyProf::Test
  def setup
    @controller = PagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def teardown
  end

  def test_show
    get :show, :id => "top"
  end
end
