class AuthenticatedController < ApplicationController
  # Authenticated users can access all actions
  allow_access :authenticated

  def index; end
end
