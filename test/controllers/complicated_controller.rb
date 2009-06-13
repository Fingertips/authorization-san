class ComplicatedController < ApplicationController
  allow_access :all, :only => :index
  allow_access :authenticated, :only => [:show, :edit, :update], :user_resource => true
  
  %w(index show edit update).each do |name|
    define_method(name) { head :ok }
  end
end
