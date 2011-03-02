module Authorization
  module BlockAccess
    protected
    # Checks if a certain action can be accessed by the role.
    # If you want to check for <tt>action_allowed?</tt>, <tt>resource_allowed?</tt> and <tt>block_allowed?</tt>
    # use <tt>access_allowed?</tt>.
    #   action_allowed?({:action => :show, :id => 1}, :editor)
    def action_allowed?(params, role=:all)
      ::ActiveSupport::Deprecation.warn("action_allowed? has been deprecated.", caller)
      die_if_undefined
      return false if (rules = access_allowed_for[role]).nil?
      !rules.detect { |rule| action_allowed_by_rule?(rule, params, role) }.nil?
    end

    def action_allowed_by_rule?(rule, params, role) #:nodoc:
      ::ActiveSupport::Deprecation.warn("action_allowed_by_rule? has been deprecated.", caller)
      return false if (action = params[:action]).nil?
      directives = rule[:directives]
      return false if directives[:only].kind_of?(Array) and !directives[:only].include?(action.to_sym)
      return false if directives[:only].kind_of?(Symbol) and directives[:only] != action.to_sym
      return false if directives[:except].kind_of?(Array) and directives[:except].include?(action.to_sym)
      return false if directives[:except].kind_of?(Symbol) and directives[:except] == action.to_sym
      true
    end

    # Checks if the resource indicated by the params can be accessed by user.
    # If you want to check for <tt>action_allowed?</tt>, <tt>resource_allowed?</tt> and <tt>block_allowed?</tt>
    # use <tt>access_allowed?</tt>.
    #   resource_allowed?({:id => 1, :organization_id => 12}, :guest, @authenticated)
    def resource_allowed?(params, role=:all, user=nil)
      ::ActiveSupport::Deprecation.warn("resource_allowed? has been deprecated.", caller)
      user ||= @authenticated
      die_if_undefined
      return false if (rules = access_allowed_for[role]).nil?
      !rules.detect { |rule| resource_allowed_by_rule?(rule, params, role, user) }.nil?
    end

    def resource_allowed_by_rule?(rule, params, role, user) #:nodoc:
      ::ActiveSupport::Deprecation.warn("resource_allowed_by_rule? has been deprecated.", caller)
      directives = rule[:directives]
      if directives[:authenticated]
        return false unless user
      end
      begin
        if directives[:user_resource]
          return false if params[:id].nil? or user.id.nil?
          return false if params[:id].to_i != user.id.to_i
        end
      rescue NoMethodError
      end
      begin
        if scope = directives[:scope]
          assoc_id = params["#{scope}_id"].to_i
          begin
            object_id = user.send(scope).id.to_i
          rescue NoMethodError
            return false
          end
          return false if assoc_id.nil? or object_id.nil?
          return false if assoc_id != object_id
        end
      rescue NoMethodError
      end
      true
    end

    # Checks if the blocks associated with the rules doesn't stop the user from acessing the resource.
    # If you want to check for <tt>action_allowed?</tt>, <tt>resource_allowed?</tt> and <tt>block_allowed?</tt>
    # use <tt>access_allowed?</tt>.
    #   block_allowed?(:guest)
    def block_allowed?(role)
      ::ActiveSupport::Deprecation.warn("block_allowed? has been deprecated.", caller)
      die_if_undefined
      return false if (rules = access_allowed_for[role]).nil?
      !rules.detect { |rule| block_allowed_by_rule?(rule) }.nil?
    end

    def block_allowed_by_rule?(rule) #:nodoc:
      ::ActiveSupport::Deprecation.warn("block_allowed_by_rule? has been deprecated.", caller)
      return false if !rule[:block].nil? and !rule[:block].bind(self).call
      true
    end
  end
end