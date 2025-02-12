class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  include Pundit::Authorization
  respond_to :json

  before_action :authenticate_user!
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def authenticate_user!
    if request.headers["Authorization"].present?
      begin
        token = request.headers["Authorization"].split(" ").last
        decoded = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key).first
        @current_user_id = decoded["sub"]
        @current_user = User.find(@current_user_id)

        # Add this check for the token's jti
        if decoded["jti"] != @current_user.jti
          return render json: { error: "Token has been revoked" }, status: :unauthorized
        end
      rescue JWT::ExpiredSignature, JWT::DecodeError, ActiveRecord::RecordNotFound
        return render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end

    render json: { error: "Unauthorized" }, status: :unauthorized unless signed_in?
  end

  def current_user
    @current_user ||= User.find(@current_user_id) if @current_user_id
  end

  def signed_in?
    @current_user_id.present?
  end

  private

  def user_not_authorized
    render json: { error: "You are not authorized to perform this action" }, status: :forbidden
  end
end
