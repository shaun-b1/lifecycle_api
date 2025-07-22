require 'rails_helper'
require 'factory_bot_rails'

RSpec.describe "Ride Recording", type: :request do
  include AuthHelpers

  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user, kilometres: 0) }
  let(:chain) { create(:chain, bicycle: bicycle, kilometres: 0) }
  let(:chainring) { create(:chainring, bicycle: bicycle, kilometres: 0) }
  let(:cassette) { create(:cassette, bicycle: bicycle, kilometres: 0) }
  let(:front_tire) { create(:tire, bicycle: bicycle, kilometres: 0) }
  let(:rear_tire) { create(:tire, bicycle: bicycle, kilometres: 0) }
  let(:front_brake) { create(:brakepad, bicycle: bicycle, kilometres: 0) }
  let(:rear_brake) { create(:brakepad, bicycle: bicycle, kilometres: 0) }
  describe "POST /api/v1/bicycles/:id/record_ride" do
    it "records ride and updates all components via API" do
      chain && chainring && cassette && front_tire && rear_tire && front_brake && rear_brake

      post "/api/v1/bicycles/#{bicycle.id}/record_ride",
        params: { distance: 50.0, notes: "Morning ride" },
        headers: jwt_auth_headers(user),
        as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response[:success]).to be true
      expect(json_response[:message]).to eq("Ride recorded successfully")
      expect(json_response[:data][:kilometres]).to eq(50.0)

      [
        bicycle, chain, cassette, chainring, front_tire, rear_tire, front_brake,
        rear_brake
      ].each do |component|
        expect(component.reload.kilometres).to eq(50)
      end

      bicycle_log = bicycle.kilometre_logs.order(:created_at).last
      expect(bicycle_log.notes).to eq("Morning ride")
    end

    it "requires authentication" do
      post "/api/v1/bicycles/#{bicycle.id}/record_ride",
        params: { distance: 25.0, notes: "Morning ride" },
        as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_response[:success]).to be false
      expect(json_response[:error][:code]).to eq("UNAUTHORIZED")
      expect(json_response[:error][:message]).to include("Authentication failed")
      expect(bicycle.reload.kilometres).to eq(0)
    end

    it "validates distance parameter" do
      post "/api/v1/bicycles/#{bicycle.id}/record_ride",
        params: { distance: 0, notes: "Morning ride" },
        headers: jwt_auth_headers(user),
        as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:success]).to be false
      expect(json_response[:error][:code]).to eq("VALIDATION_ERROR")
      expect(json_response[:error][:message]).to include("greater than zero")
      expect(bicycle.reload.kilometres).to eq(0)
    end

    it "validates distance parameter missing" do
      post "/api/v1/bicycles/#{bicycle.id}/record_ride",
        params: {},
        headers: jwt_auth_headers(user),
        as: :json


      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:success]).to be false
      expect(json_response[:error][:code]).to eq("VALIDATION_ERROR")
      expect(json_response[:error][:message]).to include("Ride distance must be greater than zero")
      expect(bicycle.reload.kilometres).to eq(0)
    end

    it "requires bicycle ownership" do
      other_user = create(:user)

      post "/api/v1/bicycles/#{bicycle.id}/record_ride",
        params: { distance: 25.0, notes: "Morning ride" },
        headers: jwt_auth_headers(other_user),
        as: :json

      expect(response).to have_http_status(:forbidden)
      expect(json_response[:success]).to be false
      expect(json_response[:error][:code]).to eq("AUTHORIZATION_FAILED")
      expect(json_response[:error][:message]).to include("not authorized")
      expect(bicycle.reload.kilometres).to eq(0)
    end

    it "handles non-existent bicycle" do
      post "/api/v1/bicycles/99999/record_ride",
        params: { distance: 25.0, notes: "Morning ride" },
        headers: jwt_auth_headers(user),
        as: :json

      expect(response).to have_http_status(:not_found)
      expect(json_response[:success]).to be false
      expect(json_response[:error][:code]).to eq("NOT_FOUND")
      expect(json_response[:error][:message]).to include("Bicycle")
      expect(bicycle.reload.kilometres).to eq(0)
    end
  end
end
