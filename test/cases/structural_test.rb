require File.expand_path('../../test_helper', __FILE__)

require 'controllers/application_controller'
require 'controllers/users_controller'
require 'models/resource'

class StructuralTest < ActionController::TestCase
  tests UsersController
  
  def setup
    @controller.authenticated = Resource.new(:role => :admin)
  end
  
  test "rules should be in place" do
    assert @controller.__send__(:access_allowed_for)
  end
  
  test "role accessors should not be public" do
    assert @acontroller.public_methods.grep(/access_allowed_for/).empty?
  end
end