class BrokenBlockController < ApplicationController
  allow_access(:only => :index) { nil.unknown_method }
  allow_access :only => :show
    
  %w(index show).each do |name|
    define_method(name) { head 200 }
  end
end
