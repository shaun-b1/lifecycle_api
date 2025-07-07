module AuthHelpers
  def jwt_auth_headers(user)
    token = JWT.encode(
      {
        sub: user.id,
        exp: 24.hours.from_now.to_i,
        jti: user.jti
      },  # Add the jti claim
      Rails.application.credentials.devise_jwt_secret_key,
      'HS256'
    )
    { 'Authorization' => "Bearer #{token}" }
  end

  def authenticate_user_in_controller(user)
    auth_header = jwt_auth_headers(user)
    @request.headers['Authorization'] = auth_header['Authorization']
    controller.instance_variable_set(:@current_user_id, user.id)
    controller.instance_variable_set(:@current_user, user)
  end
end
