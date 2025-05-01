module Api
  module V1
    module Errors
      class AuthenticationError < ApiError
        def initialize(message = "Authentication failed", details = nil)
          super(message, "UNAUTHORIZED", :unauthorized, details)
        end
      end
    end
  end
end
