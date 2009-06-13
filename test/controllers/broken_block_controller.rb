class BrokenBlockController < ApplicationController
  allow_access(:only => :index) { nil.unknown_method }
  allow_access(:only => :show) { true }
  allow_access(:authenticated, :only => :edit) { @authenticated.unknown_method }
  allow_access(:admin, :only => :edit) { @authenticated.unknown_method }
    
  %w(index show edit).each do |name|
    define_method(name) { head :ok }
  end
end
