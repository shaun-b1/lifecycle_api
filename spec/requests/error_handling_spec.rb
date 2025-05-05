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
        code: "NOT_FOUND",
        details: [],
        message: "Bicycle not found",
        status: 404,
        status_text: "Not Found"
      })
    end
  end

  describe "Authorization errors" do
    it "returns 401 when token is missing" do
      get "/api/v1/bicycles/#{bicycle.id}"

      expect(response).to have_http_status(:unauthorized)
      expect(json_response[:error]).to eq({
        code: "UNAUTHORIZED",
        details: [],
        message: "Authentication failed",
        status: 401,
        status_text: "Unauthorized"
      })
    end

    it "returns 401 when token is invalid" do
      get "/api/v1/bicycles/#{bicycle.id}",
          headers: { "Authorization" => "Bearer invalid_token" }

          expect(response).to have_http_status(:unauthorized)
          expect(json_response[:error]).to eq({
            code: "UNAUTHORIZED",
            details: [],
            message: "Authentication failed",
            status: 401,
            status_text: "Unauthorized"
          })
    end

    it "returns 403 when accessing unauthorized resource" do
      other_bicycle = create(:bicycle, user: other_user)
      get "/api/v1/bicycles/#{other_bicycle.id}",
          headers: jwt_auth_headers(user)

      expect(response).to have_http_status(:forbidden)
      expect(json_response[:error]).to eq({
        code: "AUTHORIZATION_FAILED",
        details: [],
        message: "You are not authorized to perform this action",
        status: 403,
        status_text: "Forbidden"
      })
    end
  end

  describe "Parameter validation" do
    it "returns 400 when required parameters are missing" do
      post "/api/v1/bicycles",
        headers: jwt_auth_headers(user),
        params: {}

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq({
          code: "PARAMETER_MISSING",
          details: [ "Parameter bicycle is required" ],
          message: "Parameter 'bicycle' is required",
          status: 400,
          status_text: "Bad Request"
        })
    end

    it "returns 422 when record is invalid" do
      post "/api/v1/bicycles",
      headers: jwt_auth_headers(user),
      params: { bicycle: { name: "", brand: "", model: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to eq({
        code: "VALIDATION_ERROR",
        details: [ "Name can't be blank", "Brand can't be blank", "Model can't be blank" ],
        message: "Failed to create bicycle",
        status: 422,
        status_text: "Unprocessable Entity"
      })
    end
  end

  describe "Standard error" do
    it "returns 500 for unexpected errors" do
      allow_any_instance_of(Api::V1::BicyclesController).to receive(:show).and_raise(StandardError)
      get "/api/v1/bicycles/#{bicycle.id}", headers: jwt_auth_headers(user)

      expect(response).to have_http_status(:internal_server_error)
      expect(json_response[:error]).to eq({
        code: "INTERNAL_SERVER_ERROR",
        details: [],
        message: "An unexpected error occurred",
        status: 500,
        status_text: "Internal Server Error"
      })
    end
  end
end
