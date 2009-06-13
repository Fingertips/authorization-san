class AuthenticatedController < ApplicationController
  allow_access :authenticated
  
  def index
    head :ok
  end
end
