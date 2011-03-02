require File.expand_path('../../shared', __FILE__)

module AuthorizationSanTest
  module Initializer
    def self.load_dependencies
      if rails_directory
        $:.unshift(File.join(rails_directory, 'activesupport', 'lib'))
        $:.unshift(File.join(rails_directory, 'activerecord', 'lib'))
      else
        require 'rubygems'
        gem 'rails', '> 3.0'
      end
      
      require 'test/unit'
      
      require 'active_support'
      require 'active_support/test_case'
      require 'active_record'
      require 'active_record/test_case'
      require 'active_record/base' # this is needed because of dependency hell
      require 'action_controller'
      
      $:.unshift File.expand_path('../../lib', __FILE__)
      require File.join(PLUGIN_ROOT, 'rails', 'init')
    end
  end
end

AuthorizationSanTest::Initializer.start