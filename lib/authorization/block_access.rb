module Authorization
  module BlockAccess
    protected

    def die_if_undefined #:nodoc:
      if !self.respond_to?(:access_allowed_for) or access_allowed_for.nil?
        raise ArgumentError, "Please specify access control using `allow_access' in the controller"
      end
    end

    # Block access to all actions in the controller, designed to be used as a <tt>before_filter</tt>.
    #
    #   class ApplicationController < ActionController::Base
    #     before_filter :block_access
    #   end
    #
    # When there are no rules to allow the client on the requested resource it calls
    # +access_forbidden+. You can override +access_forbidden+ to halt the filter
    # chain or do something else.
    #
    # The +block_access+ method returns +true+ when access was granted. It returns
    # the same thing as +access_forbidden+ when access was forbidden.
    def block_access
      die_if_undefined
      unless @authenticated.nil?
        if @authenticated.respond_to?(:role)
          return true if _access_allowed?(params, @authenticated.role, @authenticated)
        end
        access_allowed_for.keys.each do |role|
          if @authenticated.respond_to?("#{role}?") and @authenticated.send("#{role}?")
            return true if _access_allowed?(params, role, @authenticated)
          end
        end
      end
      _access_allowed?(params, :all, @authenticated) ? true : access_forbidden
    end

    def _matches_action?(directives, action) #:nodoc:
      if directives[:only]
        directives[:only] == action or (directives[:only].respond_to?(:include?) and directives[:only].include?(action))
      elsif directives[:except]
        directives[:except] != action and !(directives[:except].respond_to?(:include?) and directives[:except].include?(action))
      else
        true
      end
    end
    
    def _matches_scope?(scope, params, authenticated) #:nodoc:
      return true if scope.nil?
      scope_id  = params["#{scope}_id"].to_i
      object_id = authenticated.send(scope).id.to_i
      (object_id > 0) and (scope_id == object_id)
    rescue NoMethodError
      false
    end
    
    def _matches_user_resource?(run, params, authenticated) #:nodoc:
      return true unless run
      authenticated_id = authenticated ? authenticated.id.to_i : 0
      (authenticated_id > 0) and (params[:id].to_i == authenticated_id)
    end
    
    def _matches_authenticated_requirement?(run, authenticated) #:nodoc:
      return true unless run
      authenticated
    end

    def _block_is_successful?(block) #:nodoc:
      block ? block.bind(self).call : true
    end

    def _access_allowed_with_rule?(rule, params, role, authenticated) #:nodoc:
      action     = params[:action].to_sym
      directives = rule[:directives]
      _matches_action?(directives, action) and
        _matches_scope?(directives[:scope], params, authenticated) and
        _matches_user_resource?(directives[:user_resource], params, authenticated) and
        _matches_authenticated_requirement?(directives[:authenticated], authenticated) and
        _block_is_successful?(rule[:block])
    end

    def _access_allowed?(params, role, authenticated=nil) #:nodoc:
      die_if_undefined
      if rules = access_allowed_for[role]
        rules.each do |rule|
          if _access_allowed_with_rule?(rule, params, role, authenticated)
            logger.debug("  \e[32mAccess GRANTED by RULE #{rule.inspect} FOR `#{role}'\e[0m")
            return true
          else
            logger.debug("  \e[31mAccess DENIED by RULE #{rule.inspect} FOR `#{role}'\e[0m")
          end
        end
      else
        logger.debug("  \e[31mCan't find rules for `#{role}'\e[0m")
      end
      false
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
      die_if_undefined
      return false if (rules = access_allowed_for[role]).nil?
      !rules.detect { |rule| block_allowed_by_rule?(rule) }.nil?
    end

    def block_allowed_by_rule?(rule) #:nodoc:
      return false if !rule[:block].nil? and !rule[:block].bind(self).call
      true
    end
  end
end