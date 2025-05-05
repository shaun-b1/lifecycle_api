
module Api
  module V1
    module Errors
      class ResourceNotFoundError < ApiError
        def initialize(resource = "Resource", details = [])
          super(
            "#{resource} not found",
            "NOT_FOUND",
            :not_found,
            details)
        end
      end
    end
  end
end
