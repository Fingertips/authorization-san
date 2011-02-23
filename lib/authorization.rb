require 'authorization/allow_access'
require 'authorization/block_access'

ActionController::Base.send(:include, Authorization::BlockAccess)
ActionController::Base.send(:extend, Authorization::AllowAccess)