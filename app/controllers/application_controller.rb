class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  include Pundit::Authorization
  respond_to :json

  before_action :authenticate_user!
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from ActiveRecord::RecordInvalid, with: :invalid_record
  rescue_from JWT::DecodeError, with: :invalid_token
  rescue_from JWT::ExpiredSignature, with: :expired_token

  protected

  def authenticate_user!
    if request.headers["Authorization"].present?
      begin
        token = request.headers["Authorization"].split(" ").last
        decoded = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key).first
        @current_user = User.find(decoded["sub"])

        if decoded["jti"] != @current_user.jti
          return render json: { error: "Token has been revoked" }, status: :unauthorized
        end
      rescue JWT::ExpiredSignature, JWT::DecodeError, ActiveRecord::RecordNotFound
        return render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end

    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user.present?
  end

  def current_user
    @current_user
  end

  private

  def user_not_authorized
    render json: {
      error: "You are not authorized to perform this action",
      code: "FORBIDDEN"
    }, status: :forbidden
  end

  def not_found
    render json: {
      error: "Resource not found",
      code: "NOT_FOUND"
    }, status: :not_found
  end

  def parameter_missing(e)
    render json: {
      error: e.message,
      code: "PARAMETER_MISSING"
    }, status: :unprocessable_entity
  end

  def invalid_record(e)
    render json: {
      error: e.record.errors.full_messages.join(", "),
      code: "INVALID_RECORD"
    }, status: :unprocessable_entity
  end

  def invalid_token
    render json: {
      error: "Invalid authentication token",
      code: "INVALID_TOKEN"
    }, status: :unauthorized
  end

  def expired_token
    render json: {
      error: "Authentication token has expired",
      code: "EXPIRED_TOKEN"
    }, status: :unauthorized
  end
end
