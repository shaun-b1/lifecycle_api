require 'rails_helper'

RSpec.describe "Error Handling", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }

  describe "Resource not found" do
    it "returns a 404 status with error message" do
      get "/api/v1/bicycles/999999", headers: jwt_auth_headers(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response[:error]).to eq({
        message: "Bicycle not found",
        code: "NOT_FOUND"
      })
    end
  end

  describe "Authorization errors" do
    it "returns 401 when token is missing" do
      get "/api/v1/bicycles/#{bicycle.id}"

      expect(response).to have_http_status(:unauthorized)
      expect(json_response[:error]).to eq({
        message: "Authentication failed",
        code: "UNAUTHORIZED"
      })
    end

    it "returns 401 when token is invalid" do
      get "/api/v1/bicycles/#{bicycle.id}",
          headers: { "Authorization" => "Bearer invalid_token" }

          expect(response).to have_http_status(:unauthorized)
          expect(json_response[:error]).to eq({
            message: "Authentication failed",
            code: "UNAUTHORIZED"
          })
    end

    it "returns 403 when accessing unauthorized resource" do
      other_bicycle = create(:bicycle, user: other_user)
      get "/api/v1/bicycles/#{other_bicycle.id}",
          headers: jwt_auth_headers(user)

      expect(response).to have_http_status(:forbidden)
      expect(json_response[:error]).to eq({
        message: "You are not authorized to perform this action",
        code: "FORBIDDEN"
      })
    end
  end

  describe "Parameter validation" do
    it "returns 422 when required parameters are missing" do
      post "/api/v1/bicycles",
        headers: jwt_auth_headers(user),
        params: {}

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:error]).to eq({
          message: "Required parameter missing: bicycle",
          code: "PARAMETER_MISSING",
          details: [ "Parameter bicycle is required" ]
        })
    end

    it "returns 422 when record is invalid" do
      post "/api/v1/bicycles",
      headers: jwt_auth_headers(user),
      params: { bicycle: { name: "", brand: "", model: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to eq({
        message: "Name can't be blank",
        code: "VALIDATION_ERROR",
        details: [ "Name can't be blank", "Brand can't be blank", "Model can't be blank" ]
      })
    end
  end

  describe "Standard error" do
    it "returns 500 for unexpected errors" do
      allow_any_instance_of(Api::V1::BicyclesController).to receive(:show).and_raise(StandardError)
      get "/api/v1/bicycles/#{bicycle.id}", headers: jwt_auth_headers(user)

      expect(response).to have_http_status(:internal_server_error)
      expect(json_response[:error]).to eq({
        message: "An unexpected error occurred",
        code: "INTERNAL_SERVER_ERROR"
      })
    end
  end
end
