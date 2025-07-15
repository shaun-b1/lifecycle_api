require "rails_helper"
require "factory_bot_rails"

describe "POST /api/v1/bicycles/:id/record_maintenance" do
  include AuthHelpers

  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle_with_worn_components, user: user) }
  let(:auth_headers) { jwt_auth_headers(user) }

  let!(:chain) { bicycle.chain }
  let!(:cassette) { bicycle.cassette }
  let!(:chainring) { bicycle.chainring }
  let!(:tires) { bicycle.tires }
  let!(:brakepads) { bicycle.brakepads }

  context "basic bicycle maintenance" do
    it "resets bicycle kilometers to zero" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: { notes: "Basic service" },
        headers: auth_headers,
        as: :json

      expect(bicycle.reload.kilometres).to eq(0)
    end

    it "creates service record with correct attributes" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: { notes: "Basic service" },
        headers: auth_headers,
        as: :json

      service = Service.last
      expect(service).to have_attributes(
        bicycle: bicycle,
        notes: "Basic service",
        service_type: "partial_replacement"
      )
    end

    it "does not create component replacement records" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: { notes: "Basic service" },
        headers: auth_headers,
        as: :json

      expect(ComponentReplacement.count).to eq(0)
    end

    it "does not create maintenance action records" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: { notes: "Basic service" },
        headers: auth_headers,
        as: :json

      expect(MaintenanceAction.count).to eq(0)
    end

    it "leaves all components unchanged" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: { notes: "Basic service" },
        headers: auth_headers,
        as: :json

      expect(chain.reload.kilometres).to eq(150)
      expect(cassette.reload.kilometres).to eq(180)
      expect(chainring.reload.kilometres).to eq(200)
      expect(tires.map(&:reload).map(&:kilometres)).to eq([120, 130])
      expect(brakepads.map(&:reload).map(&:kilometres)).to eq([90, 95])
    end
  end

  context "single component replacement" do
    it "updates old component status to replaced" do
      old_chain = bicycle.chain

      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {
          notes: "Basic service",
          replacements: {
            chain: { brand: "SRAM", model: "Rival" }
          }
        },
        headers: auth_headers,
        as: :json

      expect(old_chain.reload.status).to eq("replaced")
    end

    it "creates new component with correct specifications" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {
          notes: "Basic service",
          replacements: {
            chain: { brand: "SRAM", model: "Rival" }
          }
        },
        headers: auth_headers,
        as: :json

      expect(bicycle.reload.chain).to have_attributes(
        brand: "Sram",
        kilometres: 0.0,
        model: "Rival",
        status: "active"
      )
    end

    it "creates component replacement audit record" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {
          notes: "Basic service",
          replacements: {
            chain: { brand: "SRAM", model: "Rival" }
          }
        },
        headers: auth_headers,
        as: :json

      expect(ComponentReplacement.last).to have_attributes(
        component_type: "chain",
        new_component_specs: { "brand" => "SRAM", "model" => "Rival", "status" => "active" },
        old_component_specs: { "brand" => "Campagnolo", "kilometres" => 150.0, "model" => "Chorus",
                               "status" => "active"
                             },
        reason: "Component replacement during partial_replacement"
      )
    end

    it "leaves other components unchanged during single replacement" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {
          notes: "Basic service",
          replacements: {
            chain: { brand: "SRAM", model: "Rival" }
          }
        },
        headers: auth_headers,
        as: :json

      expect(cassette.reload.kilometres).to eq(180)
      expect(chainring.reload.kilometres).to eq(200)
      expect(tires.map(&:reload).map(&:kilometres)).to eq([ 120, 130 ])
      expect(brakepads.map(&:reload).map(&:kilometres)).to eq([ 90, 95 ])
    end

    it "resets bicycle kilometers during component replacement" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {
          notes: "Basic service",
          replacements: {
            chain: { brand: "SRAM", model: "Rival" }
          }
        },
        headers: auth_headers,
        as: :json

      expect(bicycle.reload.kilometres).to eq(0)
    end
  end

  context "multiple component replacement" do
    it "replaces multiple single components in one service" do
      old_chain = bicycle.chain
      old_cassette = bicycle.cassette

      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {
          notes: "Basic service",
          replacements: {
            chain: { brand: "SRAM", model: "Rival" },
            cassette: { brand: "SRAM", model: "Force" }
          }
        },
        headers: auth_headers,
        as: :json

      expect(old_chain.reload.status).to eq("replaced")
      expect(old_cassette.reload.status).to eq("replaced")

      expect(bicycle.reload.chain).to have_attributes(
        brand: "Sram",
        kilometres: 0.0,
        model: "Rival",
        status: "active"
      )

      expect(bicycle.reload.cassette).to have_attributes(
        brand: "Sram",
        kilometres: 0.0,
        model: "Force",
        status: "active"
      )
    end

    it "creates separate audit records for each component" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {
          notes: "Basic service",
          replacements: {
            chain: { brand: "SRAM", model: "Rival" },
            cassette: { brand: "SRAM", model: "Force" }
          }
        },
        headers: auth_headers,
        as: :json

      expect(ComponentReplacement.count).to eq(2)

      expect(ComponentReplacement.by_component('chain')).to contain_exactly(
        have_attributes(
          component_type: 'chain',
          new_component_specs: include('brand' => 'SRAM', 'model' => 'Rival')
        )
      )

      expect(ComponentReplacement.by_component('cassette')).to contain_exactly(
        have_attributes(
          component_type: 'cassette',
          new_component_specs: include('brand' => 'SRAM', 'model' => 'Force')
        )
      )
    end

    it "handles dual component replacement (tires)" do
      tire1 = bicycle.tires.first
      tire2 = bicycle.tires.last

      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {
          notes: "Basic service",
          replacements: {
            tires: [
              { brand: "Micellin", model: "Power" },
              { brand: "Micellin", model: "Power" }
            ]
          }
        },
        headers: auth_headers,
        as: :json

      expect(tire1.reload.status).to eq("replaced")
      expect(tire2.reload.status).to eq("replaced")

      new_tires = bicycle.reload.tires.where(status: 'active')
      expect(new_tires.count).to eq(2)

      new_tires.each do |tire|
        expect(tire).to have_attributes(
          brand: "Micellin",
          kilometres: 0.0,
          model: "Power",
          status: "active"
        )
      end
    end

    it "creates single audit record for dual components" do
      old_tires = bicycle.tires.to_a
      replacement_specs = { brand: "Michelin", model: "Power"}

      expected_old_specs = transform_components_to_specs(old_tires)

      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {
          notes: "Basic service",
          replacements: {
            tires: [replacement_specs, replacement_specs]
          }
        },
        headers: auth_headers,
        as: :json

      replacement_record = ComponentReplacement.last

      expect(ComponentReplacement.count).to eq(1)
      expect(replacement_record.old_component_specs).to match_array(expected_old_specs)
      expect(replacement_record.new_component_specs).to contain_exactly(
        replacement_specs.merge("status" => "active").stringify_keys,
        replacement_specs.merge("status" => "active").stringify_keys
      )
    end
  end

  context "full service" do
    it "replaces all components with default specifications" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: {
          notes: "Full service",
          full_service: true,
          default_brand: "Shimano",
          default_model: "105"
        },
        headers: auth_headers,
        as: :json

      bicycle.reload

      expect(bicycle.all_chains.where(status: "replaced").count).to eq(1)
      expect(bicycle.all_chains.where(status: "active").count).to eq(1)
      expect(bicycle.all_cassettes.where(status: "replaced").count).to eq(1)
      expect(bicycle.all_cassettes.where(status: "active").count).to eq(1)
      expect(bicycle.all_chainrings.where(status: "replaced").count).to eq(1)
      expect(bicycle.all_chainrings.where(status: "active").count).to eq(1)

      expect(bicycle.all_tires.where(status: "replaced").count).to eq(2)
      expect(bicycle.all_tires.where(status: "active").count).to eq(2)
      expect(bicycle.all_brakepads.where(status: "replaced").count).to eq(2)
      expect(bicycle.all_brakepads.where(status: "active").count).to eq(2)

      expect(bicycle.chain).to have_attributes(brand: "Shimano", model: "105", kilometres: 0.0)
      expect(bicycle.cassette).to have_attributes(brand: "Shimano", model: "105", kilometres: 0.0)
      expect(bicycle.chainring).to have_attributes(brand: "Shimano", model: "105", kilometres: 0.0)
      expect(bicycle.tires).to all(have_attributes(brand: "Shimano", model: "105", kilometres: 0.0))
      expect(bicycle.brakepads).to all(have_attributes(brand: "Shimano", model: "105", kilometres: 0.0))
    end

    it "creates audit records for all component replacements" do
      skip("Waiting for the stars to align")
      # POST with full service
      # expect ComponentReplacement.count to equal 5
      # expect chain, cassette, chainring, tires, brakepads records exist
    end

    it "sets service type to full_service" do
      skip("Waiting for the stars to align")
      # POST with full service
      # expect Service.last.service_type to equal "full_service"
    end

    it "handles component exceptions during full service" do
      skip("Waiting for the stars to align")
      # POST with full service and chain exception: SRAM/Rival
      # expect chain replaced with SRAM/Rival
      # expect other components replaced with default Shimano/105
    end

    it "validates default_brand required for full service" do
      skip("Waiting for the stars to align")
      # POST with full_service: true, default_model: "105"
      # expect validation error about missing default_brand
    end

    it "validates default_model required for full service" do
      skip("Waiting for the stars to align")
      # POST with full_service: true, default_brand: "Shimano"
      # expect validation error about missing default_model
    end
  end

  # === MAINTENANCE ACTIONS ===
  context "maintenance actions only" do
    it "records maintenance actions without replacements" do
      skip("Waiting for the stars to align")
      # POST with maintenance_actions: [cassette: "cleaned", tire: "checked pressure"]
      # expect 2 MaintenanceAction records created
      # expect no ComponentReplacement records
    end

    it "resets bicycle kilometers for maintenance-only service" do
      skip("Waiting for the stars to align")
      # POST with maintenance actions only
      # expect bicycle.reload.kilometres to equal 0
    end

    it "leaves components unchanged during maintenance actions" do
      skip("Waiting for the stars to align")
      # POST with maintenance actions only
      # expect all component kilometres and status unchanged
    end

    it "creates service record for maintenance actions" do
      skip("Waiting for the stars to align")
      # POST with maintenance actions
      # service = Service.last
      # expect service.service_type to equal "partial_replacement"
      # expect service.maintenance_actions.count to equal 2
    end
  end

  # === MIXED SCENARIOS ===
  context "mixed maintenance and replacements" do
    it "handles combined replacements and maintenance actions" do
      skip("Waiting for the stars to align")
      # POST with chain replacement + cassette maintenance action
      # expect chain replaced
      # expect cassette maintenance action recorded
      # expect no cassette replacement
    end

    it "creates correct audit trail for mixed service" do
      skip("Waiting for the stars to align")
      # POST with mixed service
      # expect 1 ComponentReplacement record
      # expect 1 MaintenanceAction record
      # expect Service links to both records
    end
  end

  # === AUTHENTICATION/AUTHORIZATION ===
  context "security" do
    it "requires valid authentication token" do
      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: { notes: "Basic service" },
        headers: nil,
        as: :json

      expect(response).to have_http_status(:unauthorized)

      expect(bicycle.reload.kilometres).to eq(100)
      expect(chain.reload.kilometres).to eq(150)
      expect(cassette.reload.kilometres).to eq(180)
      expect(chainring.reload.kilometres).to eq(200)
      expect(tires.map(&:reload).map(&:kilometres)).to eq([120, 130])
      expect(brakepads.map(&:reload).map(&:kilometres)).to eq([90, 95])
    end

    it "requires bicycle ownership" do
      other_user = create(:user)

      post "/api/v1/bicycles/#{bicycle.id}/record_maintenance",
        params: { notes: "Basic service" },
        headers: jwt_auth_headers(other_user),
        as: :json

      expect(response).to have_http_status(:forbidden)

      expect(bicycle.reload.kilometres).to eq(100)
      expect(chain.reload.kilometres).to eq(150)
      expect(cassette.reload.kilometres).to eq(180)
      expect(chainring.reload.kilometres).to eq(200)
      expect(tires.map(&:reload).map(&:kilometres)).to eq([120, 130])
      expect(brakepads.map(&:reload).map(&:kilometres)).to eq([90, 95])
    end
  end

  # === ERROR HANDLING ===
  context "error handling" do
    it "handles non-existent bicycle gracefully" do
      skip("Waiting for the stars to align")
      # POST to "/api/v1/bicycles/99999/record_maintenance"
      # expect 404 not found
    end

    it "rolls back all changes on service failure" do
      skip("Waiting for the stars to align")
      # mock MaintenanceService to raise error
      # POST with valid params
      # expect no partial database changes
      # expect appropriate error response
    end
  end

  # === AUDIT TRAIL INTEGRITY ===
  context "audit trail verification" do
    it "links service to component replacements correctly" do
      skip("Waiting for the stars to align")
      # POST with component replacements
      # service = Service.last
      # expect all ComponentReplacement.service_id equals service.id
    end

    it "links service to maintenance actions correctly" do
      skip("Waiting for the stars to align")
      # POST with maintenance actions
      # service = Service.last
      # expect all MaintenanceAction.service_id equals service.id
    end

    it "records service timestamp accurately" do
      skip("Waiting for the stars to align")
      # POST with any maintenance
      # service = Service.last
      # expect service.performed_at within 1 second of Time.current
    end

    it "preserves complete component history" do
      skip("Waiting for the stars to align")
      # POST with component replacement
      # replacement = ComponentReplacement.last
      # expect old_component_specs contains complete original data
      # expect new_component_specs contains complete new data
    end
  end
end

private

def transform_components_to_specs(components)
  components.map do |component|
    {
      "brand" => component.brand,
      "model" => component.model,
      "kilometres" => component.kilometres,
      "status" => component.status
    }
  end
end