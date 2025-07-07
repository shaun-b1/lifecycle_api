class Api::V1::Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionsFix
  respond_to :json
  skip_before_action :authenticate_user!, only: [ :create ]

  def create
    build_resource(sign_up_params)

    if resource.save
      jwt_token = request.env["warden-jwt_auth.token"]
      sign_up(resource_name, resource)

      response_data = Api::V1::ResponseService.created(
        {
          user:  Api::V1::UserSerializer.new(resource).as_json,
          token: jwt_token },
        "Signed up successfully."
      )

      render response_data
    else
      clean_up_passwords resource
      set_minimum_password_length

      raise Api::V1::Errors::ValidationError.new(
        "User couldn't be created successfully",
        resource.errors.full_messages
      )
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name)
  end

  def respond_with(resource, _opts = {})
    if resource.persisted?
      response_data = Api::V1::ResponseService.created(
        {
          user: Api::V1::UserSerializer.new(resource).as_json },
        "Signed up successfully."
      )

      render response_data
    else
      raise Api::V1::Errors::ValidationError.new(
        "User couldn't be created successfully",
        resource.errors.full_messages
      )
    end
  end
end
