require 'test_helper'

require 'controllers/all'
require 'models/resource'

class BehaviourTest < ActionController::TestCase
  test "access is denied for nonexistant actions without an access rule" do
    begin
      tests UsersController, :authenticated => Resource.new(:role => :tester, :id => 1)
      get :unknown, :id => 1
      assert_response :forbidden
    rescue AbstractController::ActionNotFound # Rails 3 behaves diffently to missing methods
      assert true
    end
  end
  
  test "roles are properly checked" do
    tests UsersController, :authenticated => Resource.new
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
    tests UsersController, :authenticated => Resource.new(:role => :tester, :id => 1)
    get :show, :id => 1
    assert_response :ok
  end
  
  test "authenticated is not allowed to access other users" do
    tests UsersController, :authenticated => Resource.new(:role => :tester, :id => 1)
    get :show, :id => 2
    assert_response :forbidden
  end
  
  test "authenticated is allowed to access within the defined scope" do
    tests UsersController, :authenticated => Resource.new(:role => :reader, :organization => Resource.new(:id => 1))
    get :show, :organization_id => 1
    assert_response :success
  end
  
  test "authenticated is not allowed to access outside of the defined scope" do
    tests UsersController, :authenticated => Resource.new(:role => :tester, :id => 1)
    get :show, :organization_id => 2
    assert_response :forbidden
  end
  test "rule without restrictions opens up the whole controller" do
    tests PublicController
    get :index
    assert_response :ok
  end
  
  test "rule with special role :authenticated allows when @authenticated is truthy" do
    tests AuthenticatedController, :authenticated => true
    get :index
    assert_response :ok
  end
  
  test "rule with special role :authenticated disallows when @authenticated is not truthy" do
    tests AuthenticatedController, :authenticated => false
    get :index
    assert_response :forbidden
  end
  
  test "rule with broken block should raise an exception when evaluated" do
    tests BrokenBlockController
    assert_raises(NoMethodError) do
      get :index
    end
  end
  
  test "rule with block should only be evaluated when the action matches" do
    tests BrokenBlockController
    assert_nothing_raised do
      get :show
    end
  end
  
  test "rule with block should only be evaluated when the role matches" do
    tests BrokenBlockController, :authenticated => Resource.new(:role => :admin)
    assert_nothing_raised do
      get :show
    end
  end
  
  test "rule with block should only be evaluated when the special role matches" do
    tests BrokenBlockController, :authenticated => true
    assert_nothing_raised do
      get :show
    end
  end
  
  test "rule with multiple roles" do
    tests MultipleRolesController, :authenticated => Resource.new
    {
      [:a, :index] => :ok,
      [:b, :index] => :ok,
      [:c, :index] => :ok,
      [:d, :index] => :ok,
      [:e, :index] => :ok,
      [:f, :index] => :ok,
      [:e, :show] => :forbidden,
      [:f, :show] => :forbidden,
      [:g, :index] => :forbidden,
      [:h, :index] => :forbidden,
      [:g, :show] => :ok,
      [:h, :show] => :ok,
    }.each do |(role, action), status|
      @controller.authenticated.role = role
      get action
      assert_response status
    end
  end
  
  test "rule with special role, user resource and action restriction, should disallow unauthenticated" do
    tests ComplicatedController
    get :show, :id => 1
    assert_response :forbidden
  end
  
  test "rule with special role, user resource and action restriction, should disallow incorrect user" do
    tests ComplicatedController, :authenticated => Resource.new(:id => 2)
    get :show, :id => 1
    assert_response :forbidden
  end
  
  test "rule with special role, user resource and action restriction, should allow correct user" do
    tests ComplicatedController, :authenticated => Resource.new(:id => 1)
    get :show, :id => 1
    assert_response :ok
  end
  
  test "controller with rule about special role, user resource and action restriction, should allow open actions" do
    tests ComplicatedController
    get :index
    assert_response :ok
  end
  
  class ActionController::Base
    class << self
      attr_accessor :_routes
    end
  end
  
  private
  
  def tests(controller, options={})
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @controller ||= controller.new
    
    if defined?(Rails) && Rails.respond_to?(:application)
      Rails.application.routes.draw do
        get ':controller(/:action(/:id(.:format)))'
      end
    elsif defined?(ActionDispatch)
      @routes = ActionDispatch::Routing::RouteSet.new
      @routes.draw { get ':controller(/:action(/:id(.:format)))' }
      @routes.finalize!
      controller._routes = @routes
    end
    
    @controller.request = @request
    @controller.params = {}
    
    @controller.authenticated = options[:authenticated]
  end
end
