require 'rails_helper'

RSpec.describe "Error Handling", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }

  describe "Resource not found" do
    it "returns a 404 status with error message" do
      get "/api/v1/bicycles/999999", headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response[:error]).to eq("Resource not found")
      expect(json_response[:code]).to eq("NOT_FOUND")
    end
  end

  describe "Authorization errors" do
    it "returns 401 when token is missing" do
      get "/api/v1/bicycles/#{bicycle.id}"

      expect(response).to have_http_status(:unauthorized)
      expect(json_response[:error]).to eq("Unauthorized")
    end

    it "returns 401 when token is invalid" do
      get "/api/v1/bicycles/#{bicycle.id}",
          headers: { "Authorization" => "Bearer invalid_token" }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response[:error]).to eq("Unauthorized")
    end

    it "returns 403 when accessing unauthorized resource" do
      other_bicycle = create(:bicycle, user: other_user)
      get "/api/v1/bicycles/#{other_bicycle.id}",
          headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
      expect(json_response[:error]).to eq("You are not authorized to perform this action")
      expect(json_response[:code]).to eq("FORBIDDEN")
    end
  end

  describe "Parameter validation" do
    it "returns 422 when required parameters are missing" do
      post "/api/v1/bicycles",
           headers: auth_headers_for(user),
           params: {}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:code]).to eq("PARAMETER_MISSING")
    end

    it "returns 422 when record is invalid" do
      post "/api/v1/bicycles",
      headers: auth_headers_for(user),
      params: { bicycle: { name: "", brand: "", model: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:code]).to eq("INVALID_RECORD")
      expect(json_response[:error]).to include("Name can't be blank")
    end
  end

  private

  def auth_headers_for(user)
    token = JWT.encode(
      { sub: user.id, exp: 24.hours.from_now.to_i, jti: user.jti },
      Rails.application.credentials.devise_jwt_secret_key,
      'HS256'
    )
    { "Authorization" => "Bearer #{token}" }
  end

  def json_response
    JSON.parse(response.body).symbolize_keys
  end
end
