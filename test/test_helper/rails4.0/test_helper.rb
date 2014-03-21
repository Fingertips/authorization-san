require File.expand_path('../../shared', __FILE__)

module AuthorizationSanTest
  module Initializer
    def self.load_dependencies
      require 'rubygems'
      gem 'rails', '~> 4.0.0'
      
      require 'test/unit'
      require 'action_controller'
      
      $:.unshift File.expand_path('../../lib', __FILE__)
      require File.join(PLUGIN_ROOT, 'rails', 'init')
      
      puts "{!} Running on Rails 4.0"
    end
  end
end

AuthorizationSanTest::Initializer.start


class ActionController::Base
  def url_options
    {
      :host => 'test.host',
      :protocol => 'http://'
    }
  end
end