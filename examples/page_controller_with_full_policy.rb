# The pages controller is a nest resource under users (ie. /users/12/pages)
class PagesController < ApplicationController
  # A user may only access her own index
  allow_access(:authenticated, :only => :index) { @authenticated == @user }
  # A user may only access her own pages
  allow_access(:authenticated, :only => :show) { @authenticated == @page.user}

  # Always find the user the pages are nested under before applying the rules
  prepend_before_filter :find_user
  # Find the page before applying the rules when the show action is called
  prepend_before_filter :find_page, :only => :show

  def index
    @pages = @user.pages
  end

  def show; end

  protected

  def find_user
    @user = User.find params[:user_id]
  end

  def find_page
    @page = Page.find params[:id]
  end
end
