require 'rails_helper'
RSpec.describe Api::V1::MaintenanceService, type: :service do
  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user, kilometres: 2000) }
  describe ".record_component_maintenance" do
    it "successfully resets component kilometres" do
      chain = create(:chain, bicycle: bicycle, kilometres: 500)

      result = Api::V1::MaintenanceService.record_component_maintenance(chain, "Chain replacement")

      expect(chain.reload.kilometres).to eq(0)
      log_entry = chain.kilometre_logs.order(:created_at).last
      expect(log_entry.event_type).to eq('maintenance')
      expect(log_entry.previous_value).to eq(500.0)
      expect(log_entry.new_value).to eq(0)
      expect(log_entry.notes).to eq("Chain replacement")
      expect(result).to be true
    end

    it "validates component exists" do
      expect {
        Api::V1::MaintenanceService.record_component_maintenance(nil, "Chain replacement")
    }.to raise_error(Api::V1::Errors::ResourceNotFoundError, "Component not found")
    end

    it "handles component save failures" do
      chain = create(:chain, bicycle: bicycle, kilometres: 300)

      allow(chain).to receive(:record_maintenance).and_return(false)
      allow(chain).to receive(:errors).and_return(
        double(full_messages: [ "Simulated failure" ])
      )

      expect {
        Api::V1::MaintenanceService.record_component_maintenance(chain, "Chain replacement")
      }.to raise_error(Api::V1::Errors::ValidationError) do |error|
        expect(error.message).to include("Failed to record component maintenance")
        expect(error.details).to include("Simulated failure")
      end
    end

    it "works with different component types" do
      tire = create(:tire, bicycle: bicycle, kilometres: 1000)
      brakepad = create(:brakepad, bicycle: bicycle, kilometres: 750)

      Api::V1::MaintenanceService.record_component_maintenance(tire, "Tire replacement")
      Api::V1::MaintenanceService.record_component_maintenance(brakepad, "Brake service")

      expect(tire.reload.kilometres).to eq(0)
      tire_log = tire.kilometre_logs.order(:created_at).last
      expect(tire_log.event_type).to eq("maintenance")
      expect(tire_log.previous_value).to eq(1000.0)
      expect(tire_log.new_value).to eq(0.0)
      expect(tire_log.notes).to eq("Tire replacement")

      expect(brakepad.reload.kilometres).to eq(0)
      brakepad_log = brakepad.kilometre_logs.order(:created_at).last
      expect(brakepad_log.event_type).to eq("maintenance")
      expect(brakepad_log.previous_value).to eq(750.0)
      expect(brakepad_log.new_value).to eq(0.0)
      expect(brakepad_log.notes).to eq("Brake service")
    end
  end

  describe ".record_bicycle_maintenance" do
    it "successfully resets bicycle and specified components" do
      chain = create(:chain, bicycle: bicycle, kilometres: 500)
      cassette = create(:cassette, bicycle: bicycle, kilometres: 800)
      tire = create(:tire, bicycle: bicycle, kilometres: 300)

      result = Api::V1::MaintenanceService.record_bicycle_maintenance(bicycle, [ :chain, :cassette ], "Drivetrain service")

      expect(bicycle.reload.kilometres).to eq(0)
      expect(chain.reload.kilometres).to eq(0)
      expect(cassette.reload.kilometres).to eq(0)
      expect(tire.reload.kilometres).to eq(300)

      bicycle_log = bicycle.kilometre_logs.order(:created_at).last
      expect(bicycle_log.event_type).to eq("maintenance")
      expect(bicycle_log.notes).to include("Drivetrain service")

      chain_log = chain.kilometre_logs.order(:created_at).last
      expect(chain_log.event_type).to eq("maintenance")

      cassette_log = cassette.kilometre_logs.order(:created_at).last
      expect(cassette_log.event_type).to include("maintenance")

      tire_logs_count_before = tire.kilometre_logs.maintenance.count
      expect(tire.kilometre_logs.maintenance.count).to eq(tire_logs_count_before)

      expect(result).to be true
    end

    it "handles multiple components of same type" do
      front_tire = create(:tire, bicycle: bicycle, kilometres: 400)
      rear_tire = create(:tire, bicycle: bicycle, kilometres: 600)
      front_brakepads = create(:brakepad, bicycle: bicycle, kilometres: 200)
      rear_brakepads = create(:brakepad, bicycle: bicycle, kilometres: 300)

      result = Api::V1::MaintenanceService.record_bicycle_maintenance(bicycle, [ :tires, :brakepads ], "Replace tires and brakepads")

      front_tire_log = front_tire.kilometre_logs.order(:created_at).last
      rear_tire_log = rear_tire.kilometre_logs.order(:created_at).last
      expect(front_tire.reload.kilometres).to eq(0)
      expect(rear_tire.reload.kilometres).to eq(0)
      expect(front_tire_log.event_type).to eq("maintenance")
      expect(rear_tire_log.event_type).to eq("maintenance")

      front_brake_log = front_brakepads.kilometre_logs.order(:created_at).last
      rear_brake_log = rear_brakepads.kilometre_logs.order(:created_at).last
      expect(front_brakepads.reload.kilometres).to eq(0)
      expect(rear_brakepads.reload.kilometres).to eq(0)
      expect(front_brake_log.event_type).to eq("maintenance")
      expect(rear_brake_log.event_type).to eq("maintenance")

      expect(bicycle.reload.kilometres).to eq(0)
      bicycle_log = bicycle.kilometre_logs.order(:created_at).last
      expect(bicycle_log.event_type).to eq("maintenance")
      expect(bicycle_log.notes).to include("Replace tires and brakepads")

      expect(result).to be true
    end

    it "validates bicycle exists" do
      expect {
        Api::V1::MaintenanceService.record_bicycle_maintenance(nil, [], "Test service")
      }.to raise_error(Api::V1::Errors::ResourceNotFoundError) do |error|
        expect(error.message).to include("Bicycle")
      end
    end

    it "handles bicycle save failures" do
      allow(bicycle).to receive(:record_maintenance).and_return(false)
      allow(bicycle).to receive(:errors).and_return(
        double(full_messages: [ "Simulated failure" ])
      )

      expect {
        Api::V1::MaintenanceService.record_bicycle_maintenance(bicycle, [], "Test Service")
      }.to raise_error(Api::V1::Errors::ValidationError) do |error|
        expect(error.message).to include("Failed to record bicycle maintenance")
        expect(error.details).to include("Simulated failure")
      end

      expect(bicycle.reload.kilometres).to eq(2000)
    end

    it "skips missing components gracefully" do
      chain = create(:chain, bicycle: bicycle, kilometres: 300)

      result = nil
      expect {
        result = Api::V1::MaintenanceService.record_bicycle_maintenance(bicycle, [ :chain, :cassette ], "Routine maintenance")
      }.not_to raise_error

      expect(chain.reload.kilometres).to eq(0)
      expect(bicycle.reload.kilometres).to eq(0)
      expect(result).to be true

      expect(bicycle.cassette).to be_nil
    end

    it "uses database transactions for atomicity" do
      chain = create(:chain, bicycle: bicycle, kilometres: 500)
      cassette = create(:cassette, bicycle: bicycle, kilometres: 1000)

      allow(bicycle).to receive(:cassette).and_return(cassette)
      allow(cassette).to receive(:record_maintenance).and_return(false)
      allow(cassette).to receive(:errors).and_return(
        double(full_messages: [ "Simulated failure" ])
      )

      expect {
        Api::V1::MaintenanceService.record_bicycle_maintenance(bicycle, [ :chain, :cassette ], "Regular maintenance")
      }.to raise_error(Api::V1::Errors::ValidationError)

      expect(bicycle.reload.kilometres).to eq(2000)
      expect(chain.reload.kilometres).to eq(500)
    end

    it "handles unexpected errors" do
      allow(bicycle).to receive(:record_maintenance).and_raise(StandardError, "Database connection lost")

      expect {
        Api::V1::MaintenanceService.record_bicycle_maintenance(bicycle, [ :chain ], "Test maintenance")
      }.to raise_error(Api::V1::Errors::ApiError) do |error|
        expect(error.error_code).to eq("MAINTENANCE_RECORDING_ERROR")
        expect(error.message).to include("unexpected error occurred")
      end
    end
  end

  describe ".record_full_service" do
    it "resets bicycle and all component types" do
      cassette = create(:cassette, bicycle: bicycle, kilometres: 800)
      chain = create(:chain, bicycle: bicycle, kilometres: 500)
      chainring = create(:chainring, bicycle: bicycle, kilometres: 1200)
      front_brakepads = create(:brakepad, bicycle: bicycle, kilometres: 200)
      rear_brakepads = create(:brakepad, bicycle: bicycle, kilometres: 200)
      front_tire = create(:tire, bicycle: bicycle, kilometres: 400)
      rear_tire = create(:tire, bicycle: bicycle, kilometres: 400)

      result = Api::V1::MaintenanceService.record_full_service(bicycle, "Complete overhaul")

      expect(bicycle.reload.kilometres).to eq(0)
      bicycle_log = bicycle.kilometre_logs.order(:created_at).last
      expect(bicycle_log.event_type).to eq("maintenance")
      expect(bicycle_log.notes).to include("Complete overhaul")

      components = [ cassette, chain, chainring, front_brakepads, rear_brakepads, front_tire, rear_tire ]
      components.each do |component|
        expect(component.reload.kilometres).to eq(0)
      end

      expect(result).to be true
    end

    it "uses default notes when none provided" do
      chain = create(:chain, bicycle: bicycle, kilometres: 500)

      result = Api::V1::MaintenanceService.record_full_service(bicycle, nil)

      bicycle_log = bicycle.kilometre_logs.order(:created_at).last
      expect(bicycle_log.notes).to include("Full service")
      expect(bicycle.reload.kilometres).to eq(0)
      expect(chain.reload.kilometres).to eq(0)

      expect(result).to be true
    end

    it "delegates to record_bicycle_maintenance correctly" do
      expect(Api::V1::MaintenanceService).to receive(:record_bicycle_maintenance)
        .with(bicycle, [ :chain, :cassette, :chainring, :tires, :brakepads ], "Custom notes")

      Api::V1::MaintenanceService.record_full_service(bicycle, "Custom notes")
    end

    it "handles bicycles with partial component sets" do
      tire = create(:tire, bicycle: bicycle, kilometres: 400)
      chain = create(:chain, bicycle: bicycle, kilometres: 350)

      result = nil
      expect {
        result = Api::V1::MaintenanceService.record_full_service(bicycle, "Custom notes")
      }.not_to raise_error

      expect(bicycle.reload.kilometres).to eq(0)
      expect(tire.reload.kilometres).to eq(0)
      expect(chain.reload.kilometres).to eq(0)
      expect(result).to be true

      expect(bicycle.cassette).to be_nil
      expect(bicycle.chainring).to be_nil
      expect(bicycle.brakepads.count).to eq(0)
    end
  end
end
