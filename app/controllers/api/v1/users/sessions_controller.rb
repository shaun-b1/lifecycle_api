class Api::V1::Users::SessionsController < Devise::SessionsController
  include RackSessionsFix
  include Devise::Controllers::Helpers

  respond_to :json
  skip_before_action :authenticate_user!, only: [ :create ]
  skip_before_action :verify_signed_out_user, only: [ :destroy ]
  before_action :configure_sign_in_params, only: [ :create ]
  before_action :authenticate_token!, only: [ :destroy ]

  def create
    user = User.find_by(email: sign_in_params[:email])
    if user&.valid_password?(sign_in_params[:password])
      sign_in user
      jwt_token = request.env["warden-jwt_auth.token"]
      render json: {
        message: "Logged in successfully.",
        user: user,
        token: jwt_token
      }, status: :ok
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  def destroy
    @user.update(jti: SecureRandom.uuid)  # This invalidates all previous tokens
    sign_out(@user)
    render json: { message: "Logged out successfully." }, status: :ok
  end

  private

  def authenticate_token!
    return render json: { error: "No token provided" }, status: :unauthorized unless token

    begin
      decoded = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key).first
      @user = User.find(decoded["sub"])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: "Invalid token" }, status: :unauthorized
    end
  end

  def token
    request.headers["Authorization"]&.split(" ")&.last
  end

  def sign_in_params
    params.require(:user).permit(:email, :password)
  end

  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [ :email, :password ])
  end
end
