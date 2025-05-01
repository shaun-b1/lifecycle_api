module Api
  module V1
    module Errors
      class AuthorizationError < ApiError
        def initialize(message = "You are not authorized to perform this action", details = nil)
          super(message, "FORBIDDEN", :forbidden, details)
        end
      end
    end
  end
end
