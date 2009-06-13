class FragileBlockController < ApplicationController
  allow_access :authenticated do
    @authenticated.not_there
  end
  
  def index; head 200; end
end
