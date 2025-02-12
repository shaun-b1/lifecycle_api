class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  respond_to :json

  before_action :authenticate_user!

  protected

  def authenticate_user!
    if request.headers["Authorization"].present?
      begin
        token = request.headers["Authorization"].split(" ").last
        decoded = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key).first
        @current_user_id = decoded["sub"]
      rescue JWT::ExpiredSignature, JWT::DecodeError
        return render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end

    render json: { error: "Unauthorized" }, status: :unauthorized unless signed_in?
  end
end
