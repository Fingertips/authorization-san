class ApplicationController < ActionController::Base
  attr_accessor :authenticated
  
  before_filter :block_access
  
  def access_forbidden
    head :forbidden
    false
  end
  
  def logger
    @logger ||= Logger.new('/dev/null')
  end
  
  def rescue_action(e) raise e end;
end