class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  include Pundit::Authorization
  include Api::V1::ErrorHandler

  respond_to :json

  before_action :authenticate_user!

  protected

  def authenticate_user!
    if request.headers["Authorization"].present?
      begin
        token = request.headers["Authorization"].split(" ").last
        decoded = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key).first
        @current_user = User.find(decoded["sub"])

        if decoded["jti"] != @current_user.jti
          error = Api::V1::Errors::TokenError.new(
            "Token has been revoked",
            [ "The token has been revoked or is invalid" ]
          )
          render json: error.to_hash, status: error.status
          return
        end
      rescue JWT::ExpiredSignature, JWT::DecodeError, ActiveRecord::RecordNotFound
        error = Api::V1::Errors::AuthenticationError.new
        render json: error.to_hash, status: error.status
        return
      end
    end

    unless @current_user.present?
      error = Api::V1::Errors::AuthenticationError.new
      render json: error.to_hash, status: error.status
    end
  end

  def current_user
    @current_user
  end
end
