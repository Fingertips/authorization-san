$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))

begin
  require 'rubygems'
rescue LoadError
end
require 'active_support'
require 'test/unit'
require 'authorization'
require 'resource'

class MethodsTest < Test::Unit::TestCase
  include Authorization::BlockAccess
  attr_accessor :params, :access_allowed_for
  
  def logger
    @logger ||= Logger.new('/dev/null')
  end
  
  def do_false
    false
  end
  
  def do_true
    true
  end

  def test_action_allowed
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
  
  def test_action_allowed_open
    @access_allowed_for = {:all => [{:directives => {}}] }
    assert_action_allowed({
      [:admin, :index] => false,
      [:all, :show] => true,
      [:unknown, :show] => false
    })
  end
  
  def test_action_allowed_closed
    @access_allowed_for = {}
    assert_action_allowed({
      [:admin, :index] => false,
      [:all, :show] => false,
      [:show, :unknown] => false
    })
  end

  def test_action_allowed_nil
    @access_allowed_for = nil
    params = HashWithIndifferentAccess.new :action => :something
    assert_raises(ArgumentError) { action_allowed?(params, :something) }
  end
  
  def test_resource_allowed_user_resource
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
  
  def test_resource_allowed_scope
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
  
  def test_resource_allowed_authenticated
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
  
  def test_block_allowed
    @access_allowed_for = {
      :admin => [{:block => MethodsTest.instance_method(:do_true)}],
      :all => [{:block => MethodsTest.instance_method(:do_false)}]
    }
    assert_block_allowed({
      :admin => true,
      :all => false
    })
  end

  def test_access_forbidden
    assert_equal false, access_forbidden
  end
  
  def test_block_access
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

  def test_block_access_closed
    @access_allowed_for = {}
    assert_equal false, block_access
  end

  def test_block_access_nil
    @access_allowed_for = nil
    assert_raises(ArgumentError) { block_access }
  end
  
  def test_block_access_on_object_with_role_and_accessors_defined
    @access_allowed_for = {:special => [{
        :directives => {}
      }]}
    @authenticated = Resource.new :role => 'user', :'special?' => true
    @params = HashWithIndifferentAccess.new :action => :new
    assert !block_access
  end
  
  def test_block_access_on_object_with_multiple_block_accessors_defined
    @access_allowed_for = {:special => [{
        :directives => {}
      }]}
    @authenticated = Resource.new :'special?' => true, :'admin?' => true
    @params = HashWithIndifferentAccess.new :action => :new
    assert !block_access    
  end
  
  def test_block_access_on_object_with_accessor_dined_on_role
    @access_allowed_for = {:user => [{
        :directives => {}
      }]}
    @authenticated = Resource.new :role => 'user', :'special?' => true
    @params = HashWithIndifferentAccess.new :action => :new
    assert !block_access
  end
  
  private
  
  def assert_action_allowed(h)
    h.each do |pair, value|
      params = HashWithIndifferentAccess.new(:action => pair.last)
      assert_equal value, action_allowed?(params, pair.first), "For #{pair.inspect} => #{value.inspect}"
    end
  end
  
  def assert_resource_allowed(h)
    h.each do |triplet, value|
      params = HashWithIndifferentAccess.new(triplet.first)
      assert_equal value, resource_allowed?(params, triplet[1], triplet.last ? Resource.new(triplet.last) : nil), "For #{triplet.inspect} => #{value.inspect}"
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