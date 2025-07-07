module Api
  module V1
    module HttpStatus
      # 2xx Success
      OK = 200
      CREATED = 201
      ACCEPTED = 202
      NO_CONTENT = 204

      # 4xx Client Errors
      BAD_REQUEST = 400
      UNAUTHORIZED = 401
      FORBIDDEN = 403
      NOT_FOUND = 404
      METHOD_NOT_ALLOWED = 405
      UNPROCESSABLE_ENTITY = 422
      TOO_MANY_REQUESTS = 429

      # 5xx Server Errors
      INTERNAL_SERVER_ERROR = 500
      NOT_IMPLEMENTED = 501
      SERVICE_UNAVAILABLE = 503

      # Mapping of symbols to status codes
      SYMBOL_MAPPING = {
        ok:                    OK,
        created:               CREATED,
        accepted:              ACCEPTED,
        no_content:            NO_CONTENT,
        bad_request:           BAD_REQUEST,
        unauthorized:          UNAUTHORIZED,
        forbidden:             FORBIDDEN,
        not_found:             NOT_FOUND,
        method_not_allowed:    METHOD_NOT_ALLOWED,
        unprocessable_entity:  UNPROCESSABLE_ENTITY,
        too_many_requests:     TOO_MANY_REQUESTS,
        internal_server_error: INTERNAL_SERVER_ERROR,
        not_implemented:       NOT_IMPLEMENTED,
        service_unavailable:   SERVICE_UNAVAILABLE }.freeze

      # Get numeric status code from symbol
      def self.code_for(symbol)
        SYMBOL_MAPPING[symbol] || INTERNAL_SERVER_ERROR
      end

      # Get descriptive reason phrase for a status code
      def self.reason_phrase(code)
        case code
        when OK then "OK"
        when CREATED then "Created"
        when ACCEPTED then "Accepted"
        when NO_CONTENT then "No Content"
        when BAD_REQUEST then "Bad Request"
        when UNAUTHORIZED then "Unauthorized"
        when FORBIDDEN then "Forbidden"
        when NOT_FOUND then "Not Found"
        when METHOD_NOT_ALLOWED then "Method Not Allowed"
        when UNPROCESSABLE_ENTITY then "Unprocessable Entity"
        when TOO_MANY_REQUESTS then "Too Many Requests"
        when INTERNAL_SERVER_ERROR then "Internal Server Error"
        when NOT_IMPLEMENTED then "Not Implemented"
        when SERVICE_UNAVAILABLE then "Service Unavailable"
        else "Unknown Status"
        end
      end
    end
  end
end
