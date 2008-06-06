$:.unshift File.dirname(__FILE__) + '/../lib'
$:.unshift(File.dirname(__FILE__))

begin
  require 'rubygems'
rescue LoadError
end
require 'active_support'
require 'action_controller'
require 'action_controller/test_process'

require 'ostruct'
require 'test/unit'

require 'resource'
require 'init'

ActionController::Base.logger = nil
ActionController::Base.ignore_missing_templates = false
ActionController::Routing::Routes.reload rescue nil

# TEST CONTROLLERS

class ApplicationController < ActionController::Base
  session :off
  before_filter :block_access
    
  def access_forbidden
    response.headers['Status'] = '403 Forbidden'
    render :text => '403 Forbidden', :status => 403
    false
  end
  
  # Purely for testing
  def authenticated=(value)
    @authenticated = value
  end
  
  def logger
    @logger ||= Logger.new('/dev/null')
  end
  
  def rescue_action(e) raise e end;
end

class UsersController < ApplicationController
  allow_access :admin
  allow_access :editor, :only => [:index, :show]
  allow_access(:guest, :only => :guest) { params[:action] == 'guest' }
  allow_access :tester, :only => :show, :user_resource => true
  allow_access :reader, :only => :show, :scope => :organization
  allow_access :only => :listing
  allow_access :only => :react
  
  %w(index show guest listing react).each do |name|
    define_method(name) { head 200 }
  end
end

class PublicController < ApplicationController
  allow_access
  
  def index; head 200; end
end

class AuthenticatedController < ApplicationController
  allow_access :authenticated
  
  def index; head 200; end
end

class BrokenBlockController < ApplicationController
  allow_access(:only => :index) { nil.unknown_method }
  allow_access :only => :show
    
  %w(index show).each do |name|
    define_method(name) { head 200 }
  end
end

class MultipleRolesController < ApplicationController
  allow_access :a, :b
  allow_access [:c, :d]
  allow_access [:e, :f], :only => :index
  allow_access :g, :h, :only => :show
  
  %w(index show).each do |name|
    define_method(name) { head 200 }
  end
end

class FragileBlockController < ApplicationController
  allow_access :authenticated do
    @authenticated.not_there
  end
  
  def index; head 200; end
end

class ComplicatedController < ApplicationController
  allow_access :all, :only => :index
  allow_access :authenticated, :only => [:show, :edit, :update], :user_resource => true
  
  %w(index show edit update).each do |name|
    define_method(name) { head 200 }
  end
end

# TESTCASES

class ControllerTest < Test::Unit::TestCase
  
  def setup
    @controller = UsersController.new
    @controller.authenticated = Resource.new :role => :admin
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  def test_structure
    assert @controller.__send__(:access_allowed_for)
  end
  
  {
    [:admin, :index] => true,
    [:admin, :show] => true,
    [:admin, :guest] => true,
    [:admin, :listing] => true,
    [:admin, :react] => true,
    [:editor, :index] => true,
    [:editor, :guest] => false,
    [:editor, :listing] => true,
    [:editor, :react] => true,
    [:guest, :index] => false,
    [:guest, :guest] => true,
    [:guest, :listing] => true,
    [:guest, :react] => true,
    [:user, :listing] => true,
    [:user, :react] => true,
    [:user, :index] => false,
  }.each do |pair, truth|
    define_method "test_access_#{pair.join('_')}" do
      @controller.authenticated = Resource.new :role => pair.first
      get pair.last
      if truth
        assert_response :success
      else
        assert_response 403
      end
    end
  end
  
  def test_access_with_user_resource
    @controller.authenticated = Resource.new :role => :tester, :id => 1
    get :show, :id => 1
    assert_response :success
  end
  
  def test_access_with_user_denied
    @controller.authenticated = Resource.new :role => :tester, :id => 1
    get :show, :id => 2
    assert_response 403
  end
  
  def test_access_with_action_denied
    @controller.authenticated = Resource.new :role => :tester, :id => 1
    get :unknown, :id => 1
    assert_response 403
  end
  
  def test_access_with_scope
    @controller.authenticated = Resource.new :role => :reader, :organization => Resource.new(:id => 1)
    get :show, :organization_id => 1
    assert_response :success
  end
  
  def test_access_with_scope_denied
    @controller.authenticated = Resource.new :role => :reader, :organization => Resource.new(:id => 1)
    get :show, :organization_id => 2
    assert_response 403
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
end
