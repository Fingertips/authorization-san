module Authorization
  module BlockAccess
    protected
    
    # Block access to all actions in the controller, designed to be used as a <tt>before_filter</tt>.
    #   class ApplicationController < ActionController::Base
    #     before_filter :block_access
    #   end
    def block_access
      die_if_undefined
      unless @authenticated.nil?
        # Find the user's roles
        roles = []
        roles << @authenticated.role if @authenticated.respond_to?(:role)
        access_allowed_for.keys.each do |role|
           roles << role.to_s if @authenticated.respond_to?("#{role}?") and @authenticated.__send__("#{role}?")
        end
        # Check if any of the roles give her access
        roles.each do |role|
          return true if access_allowed?(params, role, @authenticated)
        end
      end
      return true if access_allowed?(params, :all, @authenticated)
      access_forbidden
    end

    # Checks if access is allowed for the params, role and authenticated user.
    #   access_allowed?({:action => :show, :id => 1}, :admin, @authenticated)
    def access_allowed?(params, role, authenticated=nil)
      die_if_undefined
      if (rules = access_allowed_for[role]).nil?
        logger.debug("  \e[31mCan't find rules for `#{role}'\e[0m")
        return false
      end
      !rules.detect do |rule|
        if !action_allowed_by_rule?(rule, params, role) or !resource_allowed_by_rule?(rule, params, role, authenticated) or !block_allowed_by_rule?(rule)
          logger.debug("  \e[31mAccess DENIED by RULE #{rule.inspect} FOR `#{role}'\e[0m")
          false
        else
          logger.debug("  \e[32mAccess GRANTED by RULE #{rule.inspect} FOR `#{role}'\e[0m")
          true
        end
      end.nil?
    end

    # <tt>access_forbidden</tt> is called by <tt>block_access</tt> when access is forbidden. This method does
    # nothing by default. Make sure you return <tt>false</tt> from the method if you want to halt the filter
    # chain.
    def access_forbidden
      false
    end

    # Checks if a certain action can be accessed by the role.
    # If you want to check for <tt>action_allowed?</tt>, <tt>resource_allowed?</tt> and <tt>block_allowed?</tt>
    # use <tt>access_allowed?</tt>.
    #   action_allowed?({:action => :show, :id => 1}, :editor)
    def action_allowed?(params, role=:all)
      die_if_undefined
      return false if (rules = access_allowed_for[role]).nil?
      !rules.detect { |rule| action_allowed_by_rule?(rule, params, role) }.nil?
    end

    def action_allowed_by_rule?(rule, params, role) #:nodoc:
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
      user ||= @authenticated
      die_if_undefined
      return false if (rules = access_allowed_for[role]).nil?
      !rules.detect { |rule| resource_allowed_by_rule?(rule, params, role, user) }.nil?
    end

    def resource_allowed_by_rule?(rule, params, role, user) #:nodoc:
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
            object_id = user.__send__(scope).id.to_i
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
      die_if_undefined
      return false if (rules = access_allowed_for[role]).nil?
      !rules.detect { |rule| block_allowed_by_rule?(rule) }.nil?
    end

    def block_allowed_by_rule?(rule) #:nodoc:
      return false if !rule[:block].nil? and !rule[:block].bind(self).call
      true
    end

    def die_if_undefined #:nodoc:
      if !self.respond_to?(:access_allowed_for) or access_allowed_for.nil?
        raise ArgumentError, "Please specify access control using `allow_access' in the controller"
      end
    end
  end
end