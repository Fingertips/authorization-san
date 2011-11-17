require File.expand_path('../../shared', __FILE__)

module AuthorizationSanTest
  module Initializer
    def self.load_dependencies
      require 'rubygems'
      gem 'rails', '< 3.0'
      
      require 'test/unit'
      
      require 'active_support'
      require 'active_support/test_case'
      require 'active_record'
      require 'active_record/test_case'
      require 'active_record/base' # this is needed because of dependency hell
      require 'action_controller'
      
      $:.unshift File.expand_path('../../lib', __FILE__)
      require File.join(PLUGIN_ROOT, 'rails', 'init')
      
      puts "{!} Running on Rails 2"
    end
  end
end

AuthorizationSanTest::Initializer.start