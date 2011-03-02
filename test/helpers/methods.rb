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
