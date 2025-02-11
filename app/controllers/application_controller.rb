class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  before_action :authenticate_user!

  # This will return a 401 with a JSON response instead of redirecting
  def authenticate_user!(*args)
    super and return unless json_request?
    render json: { error: "Unauthorized" }, status: :unauthorized unless signed_in?
  end

  private

  def json_request?
    request.format.json?
  end
end
