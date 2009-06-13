class MultipleRolesController < ApplicationController
  allow_access :a, :b
  allow_access [:c, :d]
  allow_access [:e, :f], :only => :index
  allow_access :g, :h, :only => :show
  
  %w(index show).each do |name|
    define_method(name) { head 200 }
  end
end
