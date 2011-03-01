require File.expand_path('../../test_helper', __FILE__)

require 'models/resource'

class MethodsTest < ActiveSupport::TestCase
  include Authorization::BlockAccess
  
  attr_reader :access_allowed_for, :params
  
  def logger
    @logger ||= Logger.new('/dev/null')
  end
  
  def do_false
    false
  end
  
  def do_true
    true
  end
  
  test "action_allowed? sanity" do
    @access_allowed_for = {
      :admin => [{
          :directives => {}
        }],
      :editor => [{
          :directives => {:only => :index}
        }],
      :complex => [
          {:directives => {:only => :index}},
          {:directives => {:only => :show}}
        ],
      :all => [{
          :directives => {:only => :listing}
        }]
      }
    assert_action_allowed({
      [:admin, :index] => true,
      [:admin, :show] => true,
      [:admin, :unknown] => true,
      [:editor, :unknown] => false,
      [:editor, :index] => true,
      [:all, :index] => false,
      [:all, :unknown] => false,
      [:all, :listing] => true,
      [:complex, :index] => true,
      [:complex, :show] => true,
      [:complex, :unknown] => false
      })
  end
  
  test "action_allowed? sanity with directives" do
    @access_allowed_for = {:all => [{:directives => {}}] }
    assert_action_allowed({
      [:admin, :index] => false,
      [:all, :show] => true,
      [:unknown, :show] => false
    })
  end
  
  test "action_allowed? sanity without directives" do
    @access_allowed_for = {}
    assert_action_allowed({
      [:admin, :index] => false,
      [:all, :show] => false,
      [:show, :unknown] => false
    })
  end
  
  test "action_allowed? breaks when no rules are defined" do
    @access_allowed_for = nil
    params = HashWithIndifferentAccess.new :action => :something
    assert_raises(ArgumentError) { action_allowed?(params, :something) }
  end
  
  test "resource_allowed? sanity with :authenticated directive" do
    @access_allowed_for = {
      :all => [{
        :directives => {:authenticated => true}
      }]
    }
    assert !resource_allowed?({}, :admin, nil)
    assert !resource_allowed?({}, :admin, true)
    assert resource_allowed?({}, :all, true)
    assert resource_allowed?({:action => :edit}, :all, true)
  end
  
  test "resource_allowed? sanity with :user_resource directive" do
    @access_allowed_for = {
      :user => [{
        :directives => {:only => [:index, :show], :user_resource => true}
        }]
      }
    assert_resource_allowed({
      [{}, :admin, {}] => false,
      [{:id => 1}, :admin, {:id => 1}] => false,
      [{}, :admin, {:id => 1}] => false,
      [{:id => 1}, :admin, {}] => false,
      [{}, :user, {}] => false,
      [{:id => 1}, :user, {:id => 1}] => true,
      [{:id => 2}, :user, {:id => 1}] => false,
      [{:id => 1}, :user, {:id => 2}] => false,
      [{}, :user, {:id => 1}] => false,
      [{:id => 1}, :user, {}] => false,
    })
  end
  
  test "resource_allowed? sanity with :scope directive" do
    @access_allowed_for = {
      :user => [{
        :directives => {:only => [:index, :show], :scope => :organization}
        }]
      }
    assert_resource_allowed({
      [{}, :admin, {}] => false,
      [{:organization_id => 1}, :admin, {:organization => Resource.new({:id => 1})}] => false,
      [{}, :admin, {:organization => Resource.new({:id => 1})}] => false,
      [{:organization_id => 1}, :admin, {}] => false,
      [{}, :user, {}] => false,
      [{:organization_id => 1}, :user, {:organization => Resource.new({:id => 1})}] => true,
      [{}, :user, {:organization => Resource.new({:id => 1})}] => false,
      [{:organization_id => 1}, :user, {}] => false,
      [{:organization_id => 2}, :user, {:organization => Resource.new({:id => 1})}] => false,
      [{:organization_id => 1}, :user, {:organization => Resource.new({:id => 2})}] => false,
    })
  end
  
  test "block_allowed? sanity" do
    @access_allowed_for = {
      :admin => [{:block => MethodsTest.instance_method(:do_true)}],
      :all => [{:block => MethodsTest.instance_method(:do_false)}]
    }
    assert_block_allowed({
      :admin => true,
      :all => false
    })
  end
  
  test "block_access sanity" do
    @access_allowed_for = {
      :admin => [{
          :directives => {}
        }],
      :editor => [{
          :directives => {:only => :index}
        }],
      :blocked_guest => [{
          :directives => {:only => :index},
          :block => MethodsTest.instance_method(:do_false)
        }],
      :open_guest => [{
          :directives => {:only => :index},
          :block => MethodsTest.instance_method(:do_true)
        }],
      :complex => [
          {:directives => {:only => :index}},
          {:directives => {:only => :show}}
        ],
      :all => [{
          :directives => {:only => :listing}
        }]
      }
    assert_block_access({
      [:admin, :index] => true,
      [:admin, :show] => true,
      [:admin, :unknown] => true,
      [:editor, :unknown] => false,
      [:editor, :index] => true,
      [:blocked_guest, :index] => false,
      [:blocked_guest, :unknown] => false,
      [:open_guest, :index] => true,
      [:open_guest, :unknown] => false,
      [:all, :index] => false,
      [:all, :unknown] => false,
      [:all, :listing] => true,
      [:complex, :index] => true,
      [:complex, :show] => true,
      [:complex, :unknown] => false
      })
  end
  
  test "block_access breaks when no rules are defined" do
    @access_allowed_for = nil
    assert_raises(ArgumentError) { block_access }
  end
  
  test "access is denied when there are no rules" do
    @access_allowed_for = {}
    assert !block_access
  end
  
  test "access is granted when authenticated has role and accessor and a rule matches accessor" do
    @authenticated = Resource.new(:role => 'user', :'special?' => true)
    set_rules(:special => [{:directives => {}}])
    set_params(:action => :new)
    assert block_access
  end
  
  test "access is granted when authenticated has role and accessor and a rule matches role" do
    @authenticated = Resource.new(:role => 'user', :'special?' => true)
    set_rules(:user => [{:directives => {}}])
    set_params(:action => :new)
    assert block_access
  end
  
  test "access is denied when authenticated has role and accessor and NO rule matches" do
    @authenticated = Resource.new(:role => 'user', :'special?' => true)
    set_rules(:admin => [{:directives => {}}])
    set_params(:action => :new)
    assert !block_access
  end
  
  test "access is granted when authenticated has multiple accessors and a rule matches" do
    @access_allowed_for = {:special => [{
        :directives => {}
      }]}
    @authenticated = Resource.new(:'special?' => true, :'admin?' => true)
    @params = { :action => :new }.with_indifferent_access
    assert block_access
  end
  
  private
  
  def set_rules(rules)
    @access_allowed_for = rules.with_indifferent_access
  end
  
  def set_params(params)
    @params = params.with_indifferent_access
  end
  
  def assert_action_allowed(h)
    h.each do |(role, action), value|
      params = {:action => action}.with_indifferent_access
      assert_equal(value, action_allowed?(params, role), "Expected #{role} to access #{action} with params #{params.inspect}")
    end
  end
  
  def assert_resource_allowed(h)
    h.each do |(params, role, authenticated), value|
      params        = params.with_indifferent_access
      authenticated = authenticated ? Resource.new(authenticated) : nil
      assert_equal(value, resource_allowed?(params, role, authenticated), "Expected #{role} #{authenticated} to access #{params.inspect}")
    end
  end
  
  def assert_block_allowed(h)
    h.each do |role, value|
      assert_equal value, block_allowed?(role)
    end
  end
  
  def assert_block_access(h)
    h.each do |pair, value|
      @authenticated = Resource.new :role => pair.first
      @params = {:action => pair.last}
      assert_equal value, block_access, "For #{pair.inspect} => #{value.inspect}"
    end
  end
end