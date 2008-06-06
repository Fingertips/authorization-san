class UsersController < ApplicationController
  # The default is to deny all access. Every rule creates a 'hole' in this policy. You can specify multiple rules
  # per role if you want.
  
  # The 'admin' role (@authenticated.role) has access to all the actions.
  allow_access :admin
  # The 'editor' role has access to the index and show action.
  allow_access :editor, :only => [:index, :show]
  # The 'user' role has access to the index, show, edit and update role only if the resource he's editing is the same
  # as the user resource.
  allow_access :user, :only => [:index, :show, :edit, :update], :user_resource => true
  # The 'guest' role has access to the index and show action if the Proc returns true.
  allow_access(:guest, :only => [:index, :show]) { @authenticated.valid_email? }
  # Everyone can access the listing and the index action, the other actions can be accessed when it's not sunday.
  allow_access :only => :listing
  allow_access :only => :index
  allow_access() { Time.now.strftime('%A') != 'Sunday' }
  
  def index; end
  def listing; end
  def new; end
  def create; end
  def show; end
  def edit; end
  def update; end
  def destroy; end
end
