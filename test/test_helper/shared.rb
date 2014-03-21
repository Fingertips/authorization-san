module AuthorizationSanTest
  module Initializer
    PLUGIN_ROOT = File.expand_path('../../../', __FILE__)
    
    def self.start
      load_dependencies
      
      begin
        if const_defined?(:ActionDispatch)
          ActionDispatch::Routing::Routes.reload
        else
          ActionController::Routing::Routes.reload
        end
        require 'active_support/core_ext/proc'
      rescue
      end
    end
  end
end