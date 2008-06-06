require 'authorization'

ActionController::Base.send :include, Authorization::BlockAccess
ActionController::Base.send :extend, Authorization::AllowAccess