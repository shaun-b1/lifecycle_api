class Api::V1::Users::SessionsController < Devise::SessionsController
  include RackSessionsFix
  respond_to :json

  def create
    user = User.find_by(email: params[:user][:email])
    if user&.valid_password?(params[:user][:password])
      sign_in user
      super
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  def destroy
    if current_user
      sign_out(current_user)
      respond_to_on_destroy
    else
      render json: {
        status: 401,
        message: "No active session found."
      }, status: :unauthorized
    end
  end

  private

  def respond_with(resource, _opts = {})
    render json: {
      status: { code: 200, message: "Logged in successfully." },
      data: Api::V1::UserSerializer.new(resource)
    }
  end

  def respond_to_on_destroy
    render json: {
      status: 200,
      message: "Logged out successfully"
    }, status: :ok
  end
end
