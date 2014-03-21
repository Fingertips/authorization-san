if (Proc.new {}).respond_to?(:bind)
  require 'test_helper'

  require 'models/resource'
  require 'helpers/methods'
  require 'helpers/collector'

  class DeprecatedTest < ActiveSupport::TestCase
    include Authorization::BlockAccess
    include MethodsHelpers
  
    def setup
      @stderr = $stderr
      $stderr = Collector.new
    end
  
    def teardown
      $stderr = @stderr
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
        :admin => [{:block => do_true}],
        :all => [{:block => do_false}]
      }
      assert_block_allowed({
        :admin => true,
        :all => false
      })
    end
  end
end