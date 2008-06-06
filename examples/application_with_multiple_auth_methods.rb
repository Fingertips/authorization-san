class ApplicationController < ActionController::Base
  before_filter :find_authenticated, :block_access

  protected

  # Find the authenticated user, cookie based authentication for browser users and HTTP Basic Authentication for
  # API users. Note that this does not allow you to get HTML resources when logged in through Basic Auth.
  def find_authenticated
    respond_to do |format|
      format.html do
        @authenticated = Person.find_by_id session[:authenticated_id] unless session[:authenticated_id].nil?
      end
      format.xml do
        @authenticated = authenticate_with_http_basic { |username, password| User.authenticate(username, password) }
      end
    end
  end

  # Access was forbidden to client requesting the resource. React to that appropriately. Note that this reply is very
  # bare bones and you might want to return more elaborate responses in a real application.
  def access_forbidden
    unless @authenticated
      # The user is not authenticated; ask for credentials
      respond_to do |format|
        format.html { redirect_to login_url }
        format.xml { request_http_basic_authentication "Accounting" }
      end
    else
      # The user is authentication but unauthorized for this resource
      head :forbidden
    end
  end
end
