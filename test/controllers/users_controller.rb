class UsersController < ApplicationController
  allow_access :admin
  allow_access :editor, :only => [:index, :show]
  allow_access(:guest, :only => :guest) { params[:action] == 'guest' }
  allow_access :tester, :only => :show, :user_resource => true
  allow_access :reader, :only => :show, :scope => :organization
  allow_access :only => :listing
  allow_access :only => :react
  
  %w(index show guest listing react).each do |name|
    define_method(name) { head :ok }
  end
end
