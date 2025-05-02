module Api
  module V1
    module Errors
      class ValidationError < ApiError
        def initialize(message = "Validation failed", details = [])
          super(message, "VALIDATION_ERROR", :unprocessable_entity, details)
        end
      end
    end
  end
end
