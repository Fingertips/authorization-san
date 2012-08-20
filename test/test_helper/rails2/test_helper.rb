require File.expand_path('../../shared', __FILE__)

module AuthorizationSanTest
  module Initializer
    def self.load_dependencies
      require 'rubygems'
      gem 'rails', '~> 2.3.0'
      
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

unless RUBY_VERSION < '1.9'
  module ActiveSupport
    module Dependencies
      def load_without_new_constant_marking(*args,&blk)
        super(*args,&blk)
      rescue LoadError
        nil
      end
    end
  end
end

AuthorizationSanTest::Initializer.start