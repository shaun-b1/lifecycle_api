module Api
  module V1
    module Errors
      class ParameterMissingError < ApiError
        def initialize(param, details = nil)
          message = "Required parameter missing: #{param}"
          super(message, "PARAMETER_MISSING", :unprocessable_entity, details)
        end
      end
    end
  end
end
