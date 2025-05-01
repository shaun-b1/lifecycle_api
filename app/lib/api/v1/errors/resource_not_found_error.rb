
module Api
  module V1
    module Errors
      class ResourceNotFoundError < ApiError
        def initialize(resource = "Resource")
          super("#{resource} not found", "NOT_FOUND", :not_found)
        end
      end
    end
  end
end
