module Api
  module V1
    module Errors
      class ApiError < StandardError
        attr_reader :code, :status, :details

        def initialize(message = nil, code = nil, status = nil, details = nil)
          @message = message
          @code = code
          @status = status
          @details = details || []
          super(message)
        end

        def to_hash
          error_hash = {
            error: {
              message: @message,
              code: @code
            }
          }

          error_hash[:error][:details] = @details if @details.present?

          error_hash
        end
      end
    end
  end
end
