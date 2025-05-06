module Api
  module V1
    module Errors
      class TokenError < ApiError
        def initialize(message = nil, details = [])
          super(
            message || "Invalid or expired token",
            "TOKEN_ERROR",
            :unauthorized,
            details
          )
        end
      end
    end
  end
end
