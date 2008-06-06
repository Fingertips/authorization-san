module Authorization
  module AllowAccess
    # By default you block all access to the controller with <tt>block_access</tt>, with <tt>allow_access</tt> you
    # specify who can access the actions on the controller under certain conditions. <tt>allow_access</tt> can deal
    # with accounts with and without roles.
    # 
    # *Examples*
    #
    # Everyone can access all actions on the controller.
    #   allow_access
    #   allow_access :all
    # Everyone with the admin role can access the controller.
    #   allow_access :admin
    # Everyone with the admin and editor role can access the controller.
    #   allow_access :admin, :editor
    # Everyone with the editor role can access the index. show, edit and update actions.
    #   allow_access :editor, :only => [:index, :show, :edit, :update]
    # A coordinator can do anything the admin can, except for delete
    #   allow_access :coordinator, :except => :destroy
    # Everyone with the admin and editor role can access the show action.
    #   allow_access :admin, :editor, :action => :show
    # A guest can view all resources if he has view permissions. The block is evaltuated in the controller's instance.
    # Note that rules are evaluated when <tt>block_access</tt> is run.
    #   allow_access(:guest, :only => [:index, :show]) { @authenticated.view_permission? }
    # Specifying a role is optional, if you don't specify a role the rule is added for the default role <tt>:all</tt>.
    #   allow_access(:only => :unsubscribe) { @authenticated.subscribed? }
    # Only allow authenticated users, :authenticated is a special role meaning all authenticated users.
    #   allow_access :authenticated
    # You need to be authenticated for the secret action
    #   allow_access :all, :except => :secret
    #   allow_access :authenticated, :only => :secret
    #
    # The following special directives might be a little hard to explain, I will give the equivalent rule with the
    # block access.
    #
    # Imagine we have a user controller, every user has an organization association. The users resource is nested
    # in the organization resource like this.
    #   map.resources :organizations { |org| org.resources :users }
    # Now we want the user to edit his own resource (for instance to update the password).
    #   allow_access :only => [:index, :show, :edit, :update], :user_resource => true
    #   allow_access(:only => [:index, :show, :edit, :update]) do
    #     @authenticated.id == params[:id].to_i
    #   end
    # We could also specify that a user can edit everything in his own organization.
    #   allow_access :only => [:index, :show, :edit, :update], :scope => :organization
    #   allow_access(:only => [:index, :show, :edit, :update]) do
    #     @authenticated.organization.id == params[:organization_id].to_i
    #   end
    def allow_access(*args, &block)
      self.class_inheritable_accessor(:access_allowed_for) unless self.respond_to?(:access_allowed_for)
      self.access_allowed_for ||= HashWithIndifferentAccess.new
      if args.first.kind_of?(Hash) || args.empty?
        self.access_allowed_for[:all] ||= []
        self.access_allowed_for[:all] << {
          :directives => args.first || {},
          :block => block
        }
      else
        directives = args.last.kind_of?(Hash) ? args.pop : {}
        roles = args.flatten
        if roles.delete(:authenticated) or roles.delete('authenticated')
          roles = [:all] if roles.empty?
          directives[:authenticated] = true
        end
        roles.each do |role|
          self.access_allowed_for[role.to_s] ||= []
          self.access_allowed_for[role.to_s] << {
            :directives => directives,
            :block => block
          }
        end
      end
    end
  end
end