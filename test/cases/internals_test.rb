require File.expand_path('../../test_helper', __FILE__)

require 'models/resource'
require 'helpers/methods'

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