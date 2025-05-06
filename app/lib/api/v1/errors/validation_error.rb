module Api
  module V1
    module Errors
      class ValidationError < ApiError
        def initialize(message = nil, details = [])
          super(
            message || "Validation failed",
            "VALIDATION_ERROR",
            :unprocessable_entity,
            details
          )
        end
      end
    end
  end
end
