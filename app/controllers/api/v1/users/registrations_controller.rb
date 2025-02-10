class Api::V1::Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionsFix
  respond_to :json

  before_action :configure_devise_mapping

  def create
    Rails.logger.info "Devise mappings: #{Devise.mappings}"
    build_resource(sign_up_params)

    if resource.save
      sign_up(resource_name, resource)
      respond_with resource, location: after_sign_up_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  private

  def configure_devise_mapping
    Rails.logger.info "Before action: Setting Devise mapping for user"
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name)
  end

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        status: { code: 200, message: "Signed up successfully." },
        data: Api::V1::UserSerializer.new(resource)
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
