class PublicController < ApplicationController
  # Everyone can access all actions
  allow_access

  def index; end
end
