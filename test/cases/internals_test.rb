require File.expand_path('../../test_helper', __FILE__)

require 'models/resource'

module MethodsHelpers
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
    h.each do |(role, action), expected|
      @authenticated = Resource.new(:role => role)
      @params = {:action => action}.with_indifferent_access
      assert_equal(expected, block_access, "Expected #{role} #{@authenticated} #{expected ? '' : 'NOT '}to access #{action}")
    end
  end
end

class BlockAccessTest < ActiveSupport::TestCase
  include Authorization::BlockAccess
  include MethodsHelpers
  
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
          :block => self.class.instance_method(:do_false)
        }],
      :open_guest => [{
          :directives => {:only => :index},
          :block => self.class.instance_method(:do_true)
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
end

class AccessByRuleTest < ActiveSupport::TestCase
  include Authorization::BlockAccess
  include MethodsHelpers
  
  test "matches action when there are no restrictions on action" do
    assert _matches_action?({}, :new)
  end
  
  test "matches action when there are no restrictions on action and no action" do
    assert _matches_action?({}, nil)
  end
  
  test "matches action when there are inclusive restrictions on action (array)" do
    assert _matches_action?({:only => [:index, :new, :create]}, :index)
  end
  
  test "matches action when there are inclusive restrictions on action (symbol)" do
    assert _matches_action?({:only => :index}, :index)
  end
  
  test "matches action when there are exclusive restrictions on action (array)" do
    assert _matches_action?({:except => [:update, :create, :delete]}, :index)
  end
  
  test "matches action when there are exclusive restrictions on action (symbol)" do
    assert _matches_action?({:except => :update}, :index)
  end
  
  test "does not match action when there are inclusive restrictions on action (array)" do
    assert !_matches_action?({:only => [:index, :new, :create]}, :update)
  end
  
  test "does not match action when there are inclusive restrictions on action (symbol)" do
    assert !_matches_action?({:only => :index}, :update)
  end
  
  test "does not match action when there are exclusive restrictions on action (array)" do
    assert !_matches_action?({:except => [:update, :create, :delete]}, :update)
  end
  
  test "does not match action when there are exclusive restrictions on action (symbol)" do
    assert !_matches_action?({:except => :update}, :update)
  end
  
  test "accepts a block when it's not there" do
    assert _block_is_successful?(nil)
  end
  
  test "accepts a block when it returns true" do
    assert _block_is_successful?(lambda { true })
  end
  
  test "refuses a block when it returns false" do
    assert !_block_is_successful?(lambda { false })
  end
  
  test "matches scope when there is no scope" do
    assert _matches_scope?(nil, {}, nil)
  end
  
  test "matches scope when the object ID matches the ID in the params" do
    assert _matches_scope?(:organization,
      {:organization_id => 12}.with_indifferent_access,
      Resource.new(:organization => Resource.new(:id => 12)))
  end
  
  test "does not match scope when the ID in the params is blank" do
    assert !_matches_scope?(:organization,
      {}.with_indifferent_access,
      Resource.new(:organization => Resource.new(:id => 12)))
  end
  
  test "does not match scope when the object ID is nil" do
    assert !_matches_scope?(:organization,
      {:organization_id => 12}.with_indifferent_access,
      Resource.new(:organization => Resource.new(:id => nil)))
  end
  
  test "does not match scope when both params are blank and the object ID is nil" do
    assert !_matches_scope?(:organization,
      {}.with_indifferent_access,
      Resource.new(:organization => Resource.new(:id => nil)))
  end
  
  test "does not match scope when the object ID does not match the ID in the params" do
    assert !_matches_scope?(:organization,
      {:organization_id => 32 }.with_indifferent_access,
      Resource.new(:organization => Resource.new(:id => 65)))
  end
  
  test "matches user resource when it doesn't have to run" do
    assert _matches_user_resource?(false, {}, nil)
  end
  
  test "matches user resource when it matches the params" do
    assert _matches_user_resource?(true, {:id => 12}.with_indifferent_access, Resource.new(:id => 12))
  end
  
  test "does not match user resource when the params are empty" do
    assert !_matches_user_resource?(true, {}.with_indifferent_access, Resource.new(:id => 12))
  end
  
  test "does not match user resource when the params are wrong" do
    assert !_matches_user_resource?(true, {:id => 32}.with_indifferent_access, Resource.new(:id => 12))
  end
  
  test "does not match user resource when the resource has no ID" do
    assert !_matches_user_resource?(true, {:id => 12}.with_indifferent_access, Resource.new(:id => nil))
  end
  
  test "matches authenticated requirement when it doesn't have to run (boolean)" do
    assert _matches_authenticated_requirement?(false, nil)
  end
  
  test "matches authenticated requirement when it doesn't have to run (nil)" do
    assert _matches_authenticated_requirement?(nil, nil)
  end
  
  test "matches authenticated requirement when authenticated is thruthy" do
    assert _matches_authenticated_requirement?(true, Resource.new)
  end
  
  test "does not match authenticated requirement when authenticated is not thruthy (boolean)" do
    assert !_matches_authenticated_requirement?(true, false)
  end
  
  test "does not match authenticated requirement when authenticated is not thruthy (nil)" do
    assert !_matches_authenticated_requirement?(true, nil)
  end
end

class DeprecatedInternalsTest < ActiveSupport::TestCase
  include Authorization::BlockAccess
  include MethodsHelpers
  
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
      :admin => [{:block => self.class.instance_method(:do_true)}],
      :all => [{:block => self.class.instance_method(:do_false)}]
    }
    assert_block_allowed({
      :admin => true,
      :all => false
    })
  end
end