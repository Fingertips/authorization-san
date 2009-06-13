class PublicController < ApplicationController
  allow_access
  
  def index; head 200; end
end
