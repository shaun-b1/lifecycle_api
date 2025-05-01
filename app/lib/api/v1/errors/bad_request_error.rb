module Api
  module V1
    module Errors
      class BadRequestError < ApiError
        def initialize(message = "Bad request", details = nil)
          super(message, "BAD_REQUEST", :bad_request, details)
        end
      end
    end
  end
end
