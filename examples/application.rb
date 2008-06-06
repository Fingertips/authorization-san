class ApplicationController < ActionController::Base
  # You have to specify where you want these actions to appear in your filter chain. Make sure you :block_access
  # before any sensitive processing occurs.
  before_filter :find_authenticated, :block_access

  protected

  # Find the authenticated user
  def find_authenticated
    @authenticated = authenticate_with_http_basic { |username, password| User.authenticate(username, password) }
  end

  # Access was forbidden to client requesting the resource. React to that appropriately. Note that this reply is very
  # bare bones and you might want to return more elaborate responses in a real application.
  def access_forbidden
    if @authenticated.nil?
      request_http_basic_authentication "Accounting"
    else
      head :forbidden
    end
  end
end
