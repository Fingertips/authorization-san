require File.expand_path('../test_helper', __FILE__)

require 'controllers/application_controller'
require 'controllers/authenticated_controller'
require 'controllers/broken_block_controller'
require 'controllers/complicated_controller'
require 'controllers/fragile_block_controller'
require 'controllers/multiple_roles_controller'
require 'controllers/public_controller'
require 'controllers/users_controller'
require 'models/resource'

class ControllerTest < ActionController::TestCase
  def setup
    @controller = UsersController.new
    @controller.authenticated = Resource.new :role => :admin
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  def test_public_controller
    @controller = PublicController.new
    @controller.authenticated = nil
    get :index
    assert_response 200
  end
  
  def test_broken_block_controller_index_breaks
    @controller = BrokenBlockController.new
    @controller.authenticated = nil
    assert_raises(NoMethodError) do
      get :index
    end
  end
  
  def test_broken_block_controller_show_doesnt_break
    @controller = BrokenBlockController.new
    @controller.authenticated = nil
    assert_nothing_raised do
      get :show
    end
  end
  
  def test_authenticated_controller_closed
    @controller = AuthenticatedController.new
    @controller.authenticated = nil
    get :index
    assert_response 403
  end
  
  def test_authenticated_controller_open
    @controller = AuthenticatedController.new
    @controller.authenticated = true
    get :index
    assert_response 200
  end
  
  {
    [:a, :index] => true,
    [:b, :index] => true,
    [:c, :index] => true,
    [:d, :index] => true,
    [:e, :index] => true,
    [:f, :index] => true,
    [:e, :show] => false,
    [:f, :show] => false,
    [:g, :index] => false,
    [:h, :index] => false,
    [:g, :show] => true,
    [:h, :show] => true,
  }.each do |pair, truth|
    define_method "test_access_multiple_roles_#{pair.join('_')}" do
      @controller = MultipleRolesController.new
      @controller.authenticated = Resource.new :role => pair.first
      get pair.last
      if truth
        assert_response :success
      else
        assert_response 403
      end
    end
  end
  
  def test_fragile_block
    @controller = FragileBlockController.new
    @controller.authenticated = nil
    assert_nothing_raised do
      get :index
    end
  end
  
  def test_complicated_rule_forbidden
    @controller = ComplicatedController.new
    @controller.authenticated = nil
    get :show, :id => 1
    assert_response 403
  end
  
  def test_complicated_rule_correct_user
    @controller = ComplicatedController.new
    @controller.authenticated = Resource.new :id => 1
    get :show, :id => 1
    assert_response :success
  end
  
  def test_complicated_rule_incorrect_user
    @controller = ComplicatedController.new
    @controller.authenticated = Resource.new :id => 2
    get :show, :id => 1
    assert_response 403
  end
  
  def test_complicated_rule_open_action
    @controller = ComplicatedController.new
    @controller.authenticated = nil
    get :index
    assert_response :success
  end
  
  def test_visibility_of_added_methods
    assert @acontroller.public_methods.grep(/access_allowed_for/).empty?
  end
end
