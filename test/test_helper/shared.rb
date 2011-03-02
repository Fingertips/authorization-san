module AuthorizationSanTest
  module Initializer
    VENDOR_RAILS = File.expand_path('../../../../../rails', __FILE__)
    PLUGIN_ROOT = File.expand_path('../../../', __FILE__)
    
    def self.rails_directory
      if File.exist?(VENDOR_RAILS)
        VENDOR_RAILS
      end
    end
    
    def self.start
      load_dependencies
      ActionController::Routing::Routes.reload rescue nil
    end
  end
end