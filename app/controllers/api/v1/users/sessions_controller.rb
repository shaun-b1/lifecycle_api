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

      response = Api::V1::ResponseService.success(
        {
          user:  Api::V1::UserSerializer.new(user).as_json,
          token: jwt_token },
        "Logged in successfully."
      )

      render json: response
    else
      raise Api::V1::Errors::AuthenticationError.new(
        "Invalid credentials",
        [ "The provided email or password is incorrect" ]
      )
    end
  end

  def destroy
    @user.update(jti: SecureRandom.uuid)  # This invalidates all previous tokens
    sign_out(@user)

    response_data = Api::V1::ResponseService.success(
      nil,
      "Logged out successfully."
    )

    render response_data
  end

  private

  def authenticate_token!
    return raise Api::V1::Errors::TokenError.new(
      "No token provided",
      [ "Authentication token is missing" ]
    ) unless token

    begin
      decoded = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key).first
      @user = User.find(decoded["sub"])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      raise Api::V1::Errors::TokenError.new(
        "Invalid token",
        [ "The provided authentication token is invalid" ]
      )
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
