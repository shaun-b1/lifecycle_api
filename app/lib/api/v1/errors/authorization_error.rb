module Api
  module V1
    module Errors
      class AuthorizationError < ApiError
        def initialize(message = nil, details = [])
          super(
            message || "You are not authorized to perform this action",
            "AUTHORIZATION_FAILED",
            :forbidden,
            details
          )
        end
      end
    end
  end
end
