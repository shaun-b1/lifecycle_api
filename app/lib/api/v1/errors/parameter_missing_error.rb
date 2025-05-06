module Api
  module V1
    module Errors
      class ParameterMissingError < ApiError
        def initialize(param, details = [])
          super(
            "Parameter '#{param}' is required",
            "PARAMETER_MISSING",
            :bad_request,
            details
          )
        end
      end
    end
  end
end
