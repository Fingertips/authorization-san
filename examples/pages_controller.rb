# The pages controller is a nest resource under users (ie. /users/12/pages)
class PagesController < ApplicationController
  # Users can only reach pages nested under their user_id. Note that this doesn't define the complete access policy,
  # some of the authorization is still done in the actions. See pages_controller_with_full_policy.rb for an example
  # of specifying everything in access rules.
  allow_access(:authenticated) { @authenticated.to_param == params[:user_id].to_param }

  before_filter :find_user

  def index
    @pages = @user.pages
  end

  def show
    @page = @user.pages.find params[:id]
  rescue ActiveRecord::RecordNotFound
    head :forbidden
  end

  protected

  def find_user
    @user = User.find params[:user_id]
  end
end
