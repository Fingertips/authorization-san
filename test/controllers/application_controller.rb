class ApplicationController < ActionController::Base
  before_filter :block_access
  
  def access_forbidden
    response.headers['Status'] = '403 Forbidden'
    render :text => '403 Forbidden', :status => 403
    false
  end
  
  # Purely for testing
  def authenticated=(value)
    @authenticated = value
  end
  
  def logger
    @logger ||= Logger.new('/dev/null')
  end
  
  def rescue_action(e) raise e end;
end