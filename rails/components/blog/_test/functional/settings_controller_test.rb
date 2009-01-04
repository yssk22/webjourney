require File.join(File.dirname(__FILE__), "../test_helper")
require File.join(File.dirname(__FILE__), "../functional_helper")

class Blog::SettingsControllerTest < ActiveSupport::TestCase
  def setup
    @controller = Blog::SettingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_create
    login(wj_users(:yssk22)) do
      # missing title
      post :create, { :setting => {} }
      assert_response 400
      post :create, {
        :setting => {
          :title => "test_yssk22",
          :description => "this is a test."
        }
      }
      assert_response 201

      # retry : already created for yssk22's blog
      post :create, {
        :setting => {
          :title => "test_yssk22",
          :description => "this is a test."
        }
      }
      assert_response 409
    end
  end

  def test_delete
  end
end
