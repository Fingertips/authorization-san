module AuthorizationSanTest
  module Initializer
    VENDOR_RAILS = File.expand_path('../../../../rails', __FILE__)
    OTHER_RAILS = File.expand_path('../../../rails', __FILE__)
    PLUGIN_ROOT = File.expand_path('../../', __FILE__)
    
    def self.rails_directory
      if File.exist?(VENDOR_RAILS)
        VENDOR_RAILS
      elsif File.exist?(OTHER_RAILS)
        OTHER_RAILS
      end
    end
    
    def self.load_dependencies
      if rails_directory
        puts "Using Ruby on Rails from #{rails_directory}"
        $:.unshift(File.join(rails_directory, 'activesupport', 'lib'))
        $:.unshift(File.join(rails_directory, 'activerecord', 'lib'))
      else
        puts "Using Ruby on Rails from Rubygems"
        require 'rubygems' rescue LoadError
      end
      
      require 'test/unit'
      require 'active_support'
      require 'active_support/test_case'
      require 'action_controller'
      require 'action_controller/test_process'
      
      $:.unshift(File.join(PLUGIN_ROOT, 'lib'))
      
      require File.join(PLUGIN_ROOT, 'rails', 'init')
      
      $:.unshift(File.join(PLUGIN_ROOT, 'test'))
    end
    
    def self.start
      load_dependencies
    end
  end
end

AuthorizationSanTest::Initializer.start