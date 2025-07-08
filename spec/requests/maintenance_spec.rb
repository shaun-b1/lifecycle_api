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
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {  components: [], notes: "Bicycle only service" },
        headers: jwt_auth_headers(user),
        as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response[:success]).to be true
      expect(json_response[:message]).to eq("Maintenance recorded successfully")

      expect_maintenance_log(bicycle, previous: 100, new: 0)

      unchanged_components = {
        chain: 150, cassette: 180, chainring: 200, front_tire: 120, rear_tire: 130,
        front_brake: 90, rear_brake: 95
      }

      unchanged_components.each do |component_name, initial_km|
        component = send(component_name)
        expect(component.reload.kilometres).to eq(initial_km)
        expect_no_new_maintenance_logs(component)
      end
    end

    it "silently skips missing components" do
      cassette.destroy!

      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {  components: [ "chain", "cassette" ], notes: "Service available parts" },
        headers: jwt_auth_headers(user),
        as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response[:success]).to be true
      expect(json_response[:message]).to eq("Maintenance recorded successfully")

      expect(bicycle.reload.cassette).to be_nil

      expect(bicycle.reload.kilometres).to eq(0)
      expect(chain.reload.kilometres).to eq(0)

      expect_maintenance_log(bicycle, previous: 100, new: 0)
      expect_maintenance_log(chain, previous: 150, new: 0)

      expect(chainring.reload.kilometres).to eq(200)
      expect(front_tire.reload.kilometres).to eq(120)
      expect(rear_tire.reload.kilometres).to eq(130)
      expect(front_brake.reload.kilometres).to eq(90)
      expect(rear_brake.reload.kilometres).to eq(95)

      expect_no_new_maintenance_logs([ chainring, front_tire, rear_tire, front_brake, rear_brake ])
    end

    it "requires authentication" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {  components: [ "chain" ], notes: "Regular service, no authentication" },
        as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_response[:success]).to be false
      expect(json_response[:error][:code]).to eq("UNAUTHORIZED")
      expect(json_response[:error][:message]).to include("Authentication failed")

      expect(bicycle.reload.kilometres).to eq(100)
      expect(chain.reload.kilometres).to eq(150)

      expect(bicycle.kilometre_logs.maintenance.count).to eq(0)
      expect(chain.kilometre_logs.maintenance.count).to eq(0)
    end

    it "requires bicycle ownership" do
      other_user = create(:user)

      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {  components: [ "chain" ], notes: "Regular service, incorrect user authentication" },
        headers: jwt_auth_headers(other_user),
        as: :json

      expect(response).to have_http_status(:forbidden)
      expect(json_response[:success]).to be false
      expect(json_response[:error][:code]).to eq("AUTHORIZATION_FAILED")
      expect(json_response[:error][:message]).to include("not authorized")

      expect(bicycle.reload.kilometres).to eq(100)
      expect(chain.reload.kilometres).to eq(150)

      expect(bicycle.kilometre_logs.maintenance.count).to eq(0)
      expect(chain.kilometre_logs.maintenance.count).to eq(0)
    end

    it "validates components parameter format" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {  components: "chain", notes: "Regular service, component string instead of array" },
        headers: jwt_auth_headers(user),
        as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response[:success]).to be true
      expect(json_response[:message]).to eq("Maintenance recorded successfully")

      expect(chain.reload.kilometres).to eq(0)
      expect_maintenance_log(chain, previous: 150, new: 0)

      unchanged_components = {
        cassette: 180, chainring: 200, front_tire: 120,
        rear_tire: 130, front_brake: 90, rear_brake: 95
      }

      unchanged_components.each do |component_name, expected_km|
        expect(send(component_name).reload.kilometres).to eq(expected_km)
      end

      expect_no_new_maintenance_logs(unchanged_components.keys.map { |name| send(name) })
    end

    it "handles non-existent bicycle" do
      post "/api/v1/bicycles/99999/record_maintenance",
        params: {  components: "chain", notes: "Regular service, non existent bicycle" },
        headers: jwt_auth_headers(user),
        as: :json

      expect(response).to have_http_status(:not_found)
      expect(json_response[:success]).to be false
      expect(json_response[:error][:code]).to eq("NOT_FOUND")
      expect(json_response[:error][:message]).to include("Bicycle")

      expect(bicycle.reload.kilometres).to eq(100)
      expect(chain.reload.kilometres).to eq(150)

      expect(bicycle.kilometre_logs.maintenance.count).to eq(0)
      expect(chain.kilometre_logs.maintenance.count).to eq(0)
    end

    it "handles maintenance service errors gracefully" do
      allow(Api::V1::MaintenanceService)
        .to receive(:record_bicycle_maintenance)
        .and_raise(Api::V1::Errors::ValidationError.new("Simulated maintenance failure"))

      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {  components: [ "chain" ], notes: "Regular service, mocked validation error" },
        headers: jwt_auth_headers(user),
        as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:success]).to be false
      expect(json_response[:error][:code]).to eq("VALIDATION_ERROR")
      expect(json_response[:error][:message]).to include("Simulated maintenance failure")

      expect(bicycle.reload.kilometres).to eq(100)
      expect(chain.reload.kilometres).to eq(150)

      expect(bicycle.kilometre_logs.maintenance.count).to eq(0)
      expect(chain.kilometre_logs.maintenance.count).to eq(0)
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
    components_array = Array(components)

    components_array.each do |component|
      maintenance_logs_count = component.kilometre_logs.maintenance.count
      expect(maintenance_logs_count).to eq(0),
        "Expected no maintenance logs for unchanged #{component.class.name}"
    end
  end
end
