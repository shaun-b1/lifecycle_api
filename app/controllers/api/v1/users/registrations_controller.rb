class Api::V1::Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionsFix
  respond_to :json
  skip_before_action :authenticate_user!, only: [ :create ]

  def create
    build_resource(sign_up_params)

    if resource.save
      jwt_token = request.env["warden-jwt_auth.token"]
      sign_up(resource_name, resource)
      render json: {
        status: { code: 200, message: "Signed up successfully." },
        data: {
          user: Api::V1::UserSerializer.new(resource).as_json,
          token: jwt_token
        }
      }, status: :created
    else
      clean_up_passwords resource
      set_minimum_password_length
      render json: {
        status: {
          message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}"
        }
      }, status: :unprocessable_entity
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name)
  end

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        status: { code: 200, message: "Signed up successfully." },
        data: {
          user: Api::V1::UserSerializer.new(resource).as_json
        }
      }, status: :created
    else
      render json: {
        status: {
          message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}"
        }
      }, status: :unprocessable_entity
    end
  end
end
