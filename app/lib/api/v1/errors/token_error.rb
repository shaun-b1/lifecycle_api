module Api
  module V1
    module Errors
      class TokenError < ApiError
        def initialize(message = "Invalid token", details = nil)
          super(message, "TOKEN_ERROR", :unauthorized, details)
        end
      end
    end
  end
end
