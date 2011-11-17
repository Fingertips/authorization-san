module AuthorizationSanTest
  module Initializer
    PLUGIN_ROOT = File.expand_path('../../../', __FILE__)
    
    def self.start
      load_dependencies
      begin
        ActionController::Routing::Routes.reload
      rescue
      end
    end
  end
end