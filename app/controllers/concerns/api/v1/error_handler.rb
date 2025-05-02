module Api::V1::ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_standard_error
    rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
    rescue_from ActiveRecord::RecordInvalid, with: :handle_invalid_record
    rescue_from JWT::DecodeError, with: :handle_invalid_token
    rescue_from JWT::ExpiredSignature, with: :handle_expired_token
    rescue_from Api::V1::Errors::ApiError, with: :handle_api_error
    rescue_from Api::V1::Errors::ResourceNotFoundError, with: :handle_not_found_error
    rescue_from Api::V1::Errors::AuthorizationError, with: :handle_authorization_error
    rescue_from Api::V1::Errors::AuthenticationError, with: :handle_authentication_error
    rescue_from Api::V1::Errors::ValidationError, with: :handle_validation_error_object
    rescue_from Api::V1::Errors::ParameterMissingError, with: :handle_parameter_missing_error
    rescue_from Api::V1::Errors::TokenError, with: :handle_token_error
  end

  private

  def handle_api_error(exception)
    render json: exception.to_hash, status: exception.status || :internal_server_error
  end

  alias handle_validation_error_object handle_api_error
  alias handle_parameter_missing_error handle_api_error
  alias handle_token_error handle_api_error
  alias handle_not_found_error handle_api_error
  alias handle_authorization_error handle_api_error
  alias handle_authentication_error handle_api_error

  def handle_standard_error(exception)
    Rails.logger.error("Unexpected error: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))

    error = Api::V1::Errors::ApiError.new(
      "An unexpected error occurred",
      "INTERNAL_SERVER_ERROR",
      :internal_server_error
    )

    render json: error.to_hash, status: error.status
  end


  def handle_unauthorized
    error = Api::V1::Errors::AuthorizationError.new
    render json: error.to_hash, status: error.status
  end

  def handle_not_found
    error = Api::V1::Errors::ResourceNotFoundError.new
    render json: error.to_hash, status: error.status
  end

  def handle_parameter_missing(exception)
    error = Api::V1::Errors::ParameterMissingError.new(
      exception.param,
      [ "Parameter #{exception.param} is required" ]
    )
    render json: error.to_hash, status: error.status
  end

  def handle_invalid_record(exception)
    errors = exception.record.errors.full_messages


    error = Api::V1::Errors::ValidationError.new(errors.first || "Validation failed", errors)
    render json: error.to_hash, status: error.status
  end

  def handle_invalid_token
    error = Api::V1::Errors::TokenError.new("Invalid authentication token")
    render json: error.to_hash, status: error.status
  end

  def handle_expired_token
    error = Api::V1::Errors::TokenError.new("Authentication token has expired", [ "Token has expired" ])
    render json: error.to_hash, status: error.status
  end

  def handle_validation_error(resource)
    error_messages = resource.errors.full_messages

    error = Api::V1::Errors::ValidationError.new(
      error_messages.first || "Validation failed",
      error_messages
    )
    render json: error.to_hash, status: error.status
  end
end
