module Api
  module V1
    module Errors
      class ApiError < StandardError
        attr_reader :error_code, :status, :details

        def initialize(message = nil, error_code = nil, status = nil, details = [])
          @message = message || "An error occurred"
          @error_code = error_code || "API_ERROR"
          @status = status || :internal_server_error
          @details = Array(details)

          super(@message)
        end

        def to_hash
          {
            success: false,
            error: {
              code: @error_code,
              message: @message,
              details: @details,
              status: Api::V1::HttpStatus.code_for(@status),
              status_text: Api::V1::HttpStatus.reason_phrase(Api::V1::HttpStatus.code_for(@status))
            }
          }
        end
      end
    end
  end
end
