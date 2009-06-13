class AuthenticatedController < ApplicationController
  allow_access :authenticated
  
  def index; head 200; end
end
