class PublicController < ApplicationController
  allow_access
  
  def index
    head :ok
  end
end
