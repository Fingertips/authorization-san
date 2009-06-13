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
      $stdout.write('Loading Rails from ')
      if rails_directory
        puts rails_directory
        $:.unshift(File.join(rails_directory, 'activesupport', 'lib'))
        $:.unshift(File.join(rails_directory, 'activerecord', 'lib'))
      else
        puts 'rubygems'
        require 'rubygems' rescue LoadError
      end
      
      require 'test/unit'
      require 'active_support'
      require 'active_support/test_case'
      require 'action_controller'
      require 'action_controller/test_process'
      
      require File.join(PLUGIN_ROOT, 'rails', 'init')
      
      $:.unshift(File.join(PLUGIN_ROOT, 'lib'))
      $:.unshift(File.join(PLUGIN_ROOT, 'test'))
    end
    
    def self.start
      load_dependencies
      ActionController::Routing::Routes.reload rescue nil
    end
  end
end

AuthorizationSanTest::Initializer.start