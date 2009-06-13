require File.expand_path('../../test_helper', __FILE__)

require 'controllers/application_controller'
require 'controllers/users_controller'
require 'models/resource'

class BasicRulesTest < ActionController::TestCase
  tests UsersController
  
  def setup
    @controller.authenticated = Resource.new(:role => :admin)
  end
  
  test "rules should be in place" do
    assert @controller.__send__(:access_allowed_for)
  end
  
  test "access is denied for nonexistant actions without an access rule" do
    @controller.authenticated = Resource.new :role => :tester, :id => 1
    get :unknown, :id => 1
    assert_response :forbidden
  end
  
  test "roles are properly checked" do
    {
      [:admin, :index] => :ok,
      [:admin, :show] => :ok,
      [:admin, :guest] => :ok,
      [:admin, :listing] => :ok,
      [:admin, :react] => :ok,
      [:editor, :index] => :ok,
      [:editor, :guest] => :forbidden,
      [:editor, :listing] => :ok,
      [:editor, :react] => :ok,
      [:guest, :index] => :forbidden,
      [:guest, :guest] => :ok,
      [:guest, :listing] => :ok,
      [:guest, :react] => :ok,
      [:user, :listing] => :ok,
      [:user, :react] => :ok,
      [:user, :index] => :forbidden,
    }.each do |(role, action), status|
      @controller.authenticated.role = role
      get action
      assert_response status
    end
  end
  
  test "authenticated is allowed to access its own resource" do
    @controller.authenticated = Resource.new :role => :tester, :id => 1
    get :show, :id => 1
    assert_response :ok
  end
  
  test "authenticated is not allowed to access other users" do
    @controller.authenticated = Resource.new :role => :tester, :id => 1
    get :show, :id => 2
    assert_response :forbidden
  end
  
  test "authenticated is allowed to access within the defined scope" do
    @controller.authenticated = Resource.new :role => :reader, :organization => Resource.new(:id => 1)
    get :show, :organization_id => 1
    assert_response :success
  end
  
  test "authenticated is not allowed to access outside of the defined scope" do
    @controller.authenticated = Resource.new :role => :reader, :organization => Resource.new(:id => 1)
    get :show, :organization_id => 2
    assert_response :forbidden
  end
end