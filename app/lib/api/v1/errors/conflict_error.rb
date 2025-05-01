module Api
  module V1
    module Errors
      class ConflictError < ApiError
        def initialize(message = "Resource conflict", details = nil)
          super(message, "CONFLICT", :conflict, details)
        end
      end
    end
  end
end
