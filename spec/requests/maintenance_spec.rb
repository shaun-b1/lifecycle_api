require "rails_helper"

describe "POST /api/v1/bicycles/:id/record_maintenance" do
  include AuthHelpers

  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle_with_worn_components, user: user) }
  let(:auth_headers) { jwt_auth_headers(user) }

  def post_maintenance(params = {})
    post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
      params: params,
      headers: auth_headers,
      as: :json
  end

  describe "successful maintenance recording" do
    it "records basic bicycle maintenance successfully" do
      post_maintenance(notes: "Basic service")

      expect(response).to have_http_status(:success)
      expect(json_response[:success]).to be true
      expect(json_response[:message]).to include("Maintenance recorded successfully")
      expect(bicycle.reload.kilometres).to eq(0)
    end

    it "handles single component replacement" do
      post_maintenance(
        notes: "Chain replacement",
        replacements: { chain: { brand: "SRAM", model: "Rival" } }
      )

      expect(response).to have_http_status(:success)
      expect(bicycle.reload.kilometres).to eq(0)
      expect(bicycle.chain.brand).to eq("Sram")
    end

    it "handles full service requests" do
      post_maintenance(
        notes: "Full service",
        full_service: true,
        default_brand: "Shimano",
        default_model: "105"
      )

      expect(response).to have_http_status(:success)
      expect(bicycle.reload.kilometres).to eq(0)
      expect(bicycle.chain.brand).to eq("Shimano")
    end

    it "handles maintenance actions only" do
      post_maintenance(
        maintenance_actions: [
          { component_type: "cassette", action_performed: "cleaned" }
        ]
      )

      expect(response).to have_http_status(:success)
      expect(bicycle.reload.kilometres).to eq(0)
    end

    it "returns service data in response" do
      post_maintenance(notes: "Basic service")

      # The API returns the created service record
      expect(json_response[:data]).to include(
        bicycle_id: bicycle.id,
        notes: "Basic service",
        service_type: "partial_replacement"
      )
    end
  end

  describe "authentication and authorization" do
    it "requires valid authentication token" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: { notes: "Basic service" },
        headers: nil,
        as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_response[:error][:code]).to eq("UNAUTHORIZED")
    end

    it "requires bicycle ownership" do
      other_user = create(:user)
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: { notes: "Basic service" },
        headers: jwt_auth_headers(other_user),
        as: :json

      expect(response).to have_http_status(:forbidden)
      expect(json_response[:error][:code]).to eq("AUTHORIZATION_FAILED")
    end
  end

  describe "validation errors" do
    it "returns validation error for full service without required params" do
      post_maintenance(
        notes: "Full service",
        full_service: true,
        default_model: "105"
      )

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error][:code]).to eq("VALIDATION_ERROR")
      expect(json_response[:error][:message]).to include("Default brand is required")
    end
  end

  describe "error handling" do
    it "handles non-existent bicycle gracefully" do
      post "/api/v1/bicycles/99999/record_maintenance",
        params: { notes: "Basic service" },
        headers: auth_headers,
        as: :json

      expect(response).to have_http_status(:not_found)
      expect(json_response[:error]).to include(
        code: "NOT_FOUND",
        message: "Bicycle not found"
      )
    end

    it "handles service failures gracefully" do
      allow(Api::V1::MaintenanceService).to receive(:record_maintenance)
        .and_raise(StandardError.new("Service failure"))

      post_maintenance(notes: "Basic service")

      expect(response).to have_http_status(:internal_server_error)
      expect(json_response[:error][:code]).to eq("INTERNAL_SERVER_ERROR")
    end
  end
end