require 'rails_helper'
require "factory_bot_rails"

RSpec.describe "Maintenance", type: :request do
  include AuthHelpers

  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user, kilometres: 100) }

  let!(:chain) { create(:chain, bicycle: bicycle, kilometres: 150) }
  let!(:chainring) { create(:chainring, bicycle: bicycle, kilometres: 200) }
  let!(:cassette) { create(:cassette, bicycle: bicycle, kilometres: 180) }
  let!(:front_tire) { create(:tire, bicycle: bicycle, kilometres: 120) }
  let!(:rear_tire) { create(:tire, bicycle: bicycle, kilometres: 130) }
  let!(:front_brake) { create(:brakepad, bicycle: bicycle, kilometres: 90) }
  let!(:rear_brake) { create(:brakepad, bicycle: bicycle, kilometres: 95) }
  describe "POST /api/v1/bicycles/:id/record_maintenance" do
    it "resets specific components via API" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: { components: [ "chain", "cassette" ], notes: "Chain and cassette service" },
        headers: jwt_auth_headers(user),
        as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response[:success]).to be true
      expect(json_response[:message]).to eq("Maintenance recorded successfully")

      expect(bicycle.reload.kilometres).to eq(0)
      expect(chain.reload.kilometres).to eq(0)
      expect(cassette.reload.kilometres).to eq(0)
      expect(chainring.reload.kilometres).to eq(200)
      expect(front_tire.reload.kilometres).to eq(120)
      expect(rear_tire.reload.kilometres).to eq(130)
      expect(front_brake.reload.kilometres).to eq(90)
      expect(rear_brake.reload.kilometres).to eq(95)

      expect_maintenance_log(bicycle, previous: 100, new: 0)
      expect_maintenance_log(chain, previous: 150, new: 0)
      expect_maintenance_log(cassette, previous: 180, new: 0)
      expect_no_new_maintenance_logs([ chainring, front_tire, rear_tire, front_brake, rear_brake ])
    end

    it "handles full service parameter" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: { full_service: "true", notes: "Complete overhaul" },
        headers: jwt_auth_headers(user),
        as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response[:success]).to be true
      expect(json_response[:message]).to eq("Maintenance recorded successfully")

      [
        bicycle, chain, cassette, chainring, front_tire, rear_tire, front_brake,
        rear_brake
      ].each do |component|
        expect(component.reload.kilometres).to eq(0)
      end

      {
        bicycle: 100,
        chain: 150,
        cassette: 180,
        chainring: 200,
        front_tire: 120,
        rear_tire: 130,
        front_brake: 90,
        rear_brake: 95
      }.each do |component_name, initial_km|
        component = send(component_name)
        expect_maintenance_log(component, previous: initial_km, new: 0)
      end
    end

    it "full service overrides components parameter" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: { full_service: "true", components: [ "chain" ], notes: "Full service wins" },
        headers: jwt_auth_headers(user),
        as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response[:success]).to be true
      expect(json_response[:message]).to eq("Maintenance recorded successfully")

      [
        bicycle, chain, cassette, chainring, front_tire, rear_tire, front_brake,
        rear_brake
      ].each do |component|
        expect(component.reload.kilometres).to eq(0)
      end

      {
        bicycle: 100,
        chain: 150,
        cassette: 180,
        chainring: 200,
        front_tire: 120,
        rear_tire: 130,
        front_brake: 90,
        rear_brake: 95
      }.each do |component_name, initial_km|
        component = send(component_name)
        expect_maintenance_log(component, previous: initial_km, new: 0)
      end
    end

    it "handles empty components array" do
      # create user with bicycle at 50km and components

      # POST /api/v1/bicycles/:bicycle_id/record_maintenance with auth headers
      # params: { components: [], notes: "Bicycle only service" }

      # expect response status 200 OK
      # expect bicycle kilometres = 0 (bicycle still gets reset)
      # expect all component kilometres unchanged
      # expect only bicycle kilometre_log created
      skip("Yet to write")
    end

    it "silently skips missing components" do
      # create user with bicycle (with chain, but missing cassette)

      # POST /api/v1/bicycles/:bicycle_id/record_maintenance with auth headers
      # params: { components: ["chain", "cassette"], notes: "Service available parts" }

      # expect response status 200 OK
      # expect chain kilometres = 0 (reset)
      # expect no error about missing cassette
      # expect only bicycle and chain logs created
      skip("Yet to write")
    end

    it "requires authentication" do
      # create user with bicycle

      # POST /api/v1/bicycles/:bicycle_id/record_maintenance WITHOUT auth headers
      # params: { components: ["chain"] }

      # expect response status 401 Unauthorized
      # expect response success: false
      # expect response error code: "UNAUTHORIZED"
      # expect response error message mentions authentication
      # expect no changes to bicycle or components
      skip("Yet to write")
    end

    it "requires bicycle ownership" do
      # create user with bicycle
      # create other_user

      # POST /api/v1/bicycles/:bicycle_id/record_maintenance with other_user auth headers
      # params: { components: ["chain"] }

      # expect response status 403 Forbidden
      # expect response success: false
      # expect response error code: "AUTHORIZATION_FAILED"
      # expect no changes to bicycle or components
      skip("Yet to write")
    end

    it "validates components parameter format" do
      # create user with bicycle

      # POST /api/v1/bicycles/:bicycle_id/record_maintenance with auth headers
      # params: { components: "chain" }  # string instead of array

      # expect response status 200 OK  # Array(params[:components]) handles this
      # expect chain kilometres = 0
      # expect service proceeds normally
      skip("Yet to write")
    end

    it "handles non-existent bicycle" do
      # create user

      # POST /api/v1/bicycles/99999/record_maintenance with auth headers
      # params: { components: ["chain"] }

      # expect response status 404 Not Found
      # expect response success: false
      # expect response error code: "NOT_FOUND"
      # expect response error message mentions "Bicycle"
      skip("Yet to write")
    end

    it "handles maintenance service errors gracefully" do
      # create user with bicycle
      # stub MaintenanceService.record_bicycle_maintenance to raise validation error

      # POST /api/v1/bicycles/:bicycle_id/record_maintenance with auth headers
      # params: { components: ["chain"] }

      # expect response status 422 Unprocessable Entity
      # expect response success: false
      # expect response error code: "VALIDATION_ERROR"
      # expect error details include service failure message
      skip("Yet to write")
    end
  end

  private

  def expect_maintenance_log(component, previous:, new:)
    log = component.kilometre_logs.maintenance.order(:created_at).last
    expect(log).to be_present, "Expected maintenance log for #{component.class.name}"
    expect(log.event_type).to eq('maintenance')
    expect(log.previous_value).to eq(previous)
    expect(log.new_value).to eq(new)
  end

  def expect_no_new_maintenance_logs(components)
    components.each do |component|
      maintenance_logs_count = component.kilometre_logs.maintenance.count
      expect(maintenance_logs_count).to eq(0),
        "Expected no maintenance logs for unchanged #{component.class.name}"
    end
  end
end
