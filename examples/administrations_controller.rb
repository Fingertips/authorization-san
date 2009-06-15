# The administrations controller is nested under organizations (ie. /organizations/3214/administrations)
class PagesController < ApplicationController
  # The following rule only allows @authenticated if @authenticated.organization.id == params[:organization_id].
  # Roughly translated this means that the authenticated user can only access resources belonging to its own
  # organization.
  allow_access :authenticated, :scope => :organization

  def index
    @administrations = @authenticated.organization.administrations
  end
end