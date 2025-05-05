module Api
  module V1
    module Errors
      class AuthenticationError < ApiError
        def initialize(message = nil, details = [])
          super(
            message || "Authentication failed",
            "UNAUTHORIZED",
            :unauthorized,
            details
          )
        end
      end
    end
  end
end
