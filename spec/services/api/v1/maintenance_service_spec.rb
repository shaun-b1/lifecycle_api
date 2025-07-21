require "rails_helper"

RSpec.describe Api::V1::MaintenanceService do
  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle_with_worn_components, user: user) }

  let!(:chain) { bicycle.chain }
  let!(:cassette) { bicycle.cassette }
  let!(:chainring) { bicycle.chainring }
  let!(:tires) { bicycle.tires.to_a }
  let!(:brakepads) { bicycle.brakepads.to_a }

  let(:initial_bicycle_km) { bicycle.kilometres }
  let(:initial_chain_km) { chain.kilometres }
  let(:initial_cassette_km) { cassette.kilometres }
  let(:initial_chainring_km) { chainring.kilometres }
  let(:initial_tire_kms) { tires.map(&:kilometres) }
  let(:initial_brakepad_kms) { brakepads.map(&:kilometres) }

  describe ".record_maintenance" do
    describe "basic bicycle maintenance" do
      let(:result) { described_class.record_maintenance(bicycle, { notes: "Basic service" }) }

      it "resets bicycle kilometers to zero" do
        result
        expect(bicycle.reload.kilometres).to eq(0)
      end

      it "creates service record with correct attributes" do
        result
        service = Service.last
        expect(service).to have_attributes(
          bicycle: bicycle,
          notes: "Basic service",
          service_type: "partial_replacement"
        )
      end

      it "does not create component replacement records" do
        expect { result }.not_to change(ComponentReplacement, :count)
      end

      it "does not create maintenance action records" do
        expect { result }.not_to change(MaintenanceAction, :count)
      end

      it "leaves all components unchanged" do
        result
        expect(chain.reload.kilometres).to eq(initial_chain_km)
        expect(cassette.reload.kilometres).to eq(initial_cassette_km)
        expect(chainring.reload.kilometres).to eq(initial_chainring_km)
        expect(tires.map { |t| t.reload.kilometres }).to eq(initial_tire_kms)
        expect(brakepads.map { |b| b.reload.kilometres }).to eq(initial_brakepad_kms)
      end
    end

    describe "single component replacement" do
      let(:replacement_params) do
        {
          notes: "Chain replacement",
          replacements: { chain: { brand: "SRAM", model: "Rival" } }
        }
      end
      let(:result) { described_class.record_maintenance(bicycle, replacement_params) }

      it "marks old component as replaced" do
        result
        expect(chain.reload.status).to eq("replaced")
      end

      it "creates new component with correct specifications" do
        result
        new_component = bicycle.reload.chain
        expect(new_component).to have_attributes(
          brand: "Sram",
          model: "Rival",
          kilometres: 0.0,
          status: "active"
        )
      end

      it "creates component replacement audit record" do
        expect { result }.to change(ComponentReplacement, :count).by(1)

        replacement = ComponentReplacement.by_component("chain").last
        expect(replacement).to have_attributes(
          component_type: "chain",
          new_component_specs: include("brand" => "SRAM", "model" => "Rival")
        )
      end

      it "preserves other components unchanged" do
        result
        expect(cassette.reload.kilometres).to eq(initial_cassette_km)
        expect(chainring.reload.kilometres).to eq(initial_chainring_km)
        expect(tires.map { |t| t.reload.kilometres }).to eq(initial_tire_kms)
        expect(brakepads.map { |b| b.reload.kilometres }).to eq(initial_brakepad_kms)
      end
    end

    describe "multiple component replacement" do
      let(:multiple_replacement_params) do
        {
          notes: "Multiple replacements",
          replacements: {
            chain: { brand: "SRAM", model: "Rival" },
            cassette: { brand: "SRAM", model: "Force" }
          }
        }
      end
      let(:result) { described_class.record_maintenance(bicycle, multiple_replacement_params) }

      it "marks all specified components as replaced" do
        result
        expect(chain.reload.status).to eq("replaced")
        expect(cassette.reload.status).to eq("replaced")
      end

      it "creates new components with correct specifications" do
        result
        bicycle.reload
        expect(bicycle.chain).to have_attributes(
          brand: "Sram", model: "Rival", kilometres: 0.0, status: "active"
        )
        expect(bicycle.cassette).to have_attributes(
          brand: "Sram", model: "Force", kilometres: 0.0, status: "active"
        )
      end

      it "creates separate audit records for each component" do
        expect { result }.to change(ComponentReplacement, :count).by(2)

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

      it "preserves unchanged components" do
        result
        expect(chainring.reload.kilometres).to eq(initial_chainring_km)
        expect(tires.map { |t| t.reload.kilometres }).to eq(initial_tire_kms)
        expect(brakepads.map { |b| b.reload.kilometres }).to eq(initial_brakepad_kms)
      end
    end

    describe "dual component replacement" do
      let(:tire_replacement_params) do
        {
          notes: "Tire replacement",
          replacements: {
            tires: [
              { brand: "Michelin", model: "Power" },
              { brand: "Michelin", model: "Power" }
            ]
          }
        }
      end
      let(:result) { described_class.record_maintenance(bicycle, tire_replacement_params) }

      it "marks all old dual components as replaced" do
        result
        tires.each { |tire| expect(tire.reload.status).to eq("replaced") }
      end

      it "creates new dual components with correct specifications" do
        result
        new_tires = bicycle.reload.tires.where(status: 'active')
        expect(new_tires.count).to eq(2)
        expect(new_tires).to all(have_attributes(
          brand: "Michelin", model: "Power", kilometres: 0.0, status: "active"
        ))
      end

      it "creates single audit record for dual components" do
        # Capture old specs BEFORE running the service
        expected_old_specs = transform_components_to_specs(tires)

        expect { result }.to change(ComponentReplacement, :count).by(1)

        replacement_record = ComponentReplacement.last
        expected_new_specs = [
          { "brand" => "Michelin", "model" => "Power", "status" => "active" },
          { "brand" => "Michelin", "model" => "Power", "status" => "active" }
        ]

        expect(replacement_record.old_component_specs).to match_array(expected_old_specs)
        expect(replacement_record.new_component_specs).to contain_exactly(*expected_new_specs)
      end
    end

    describe "full service" do
      let(:full_service_params) do
        {
          notes: "Full service",
          full_service: true,
          default_brand: "Shimano",
          default_model: "105"
        }
      end
      let(:result) { described_class.record_maintenance(bicycle, full_service_params) }

      it "replaces all components with default specifications" do
        result
        bicycle.reload

        # Check component counts
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

        # Check specifications
        expected_attributes = { brand: "Shimano", model: "105", kilometres: 0.0 }
        expect(bicycle.chain).to have_attributes(expected_attributes)
        expect(bicycle.cassette).to have_attributes(expected_attributes)
        expect(bicycle.chainring).to have_attributes(expected_attributes)
        expect(bicycle.tires).to all(have_attributes(expected_attributes))
        expect(bicycle.brakepads).to all(have_attributes(expected_attributes))
      end

      it "creates audit records for all component replacements" do
        expect { result }.to change(ComponentReplacement, :count).by(5)
        expect(ComponentReplacement.last(5).pluck(:component_type)).to contain_exactly(
          "chain", "cassette", "chainring", "tire", "brakepad"
        )
      end

      it "sets service type to full_service" do
        result
        expect(Service.last.service_type).to eq("full_service")
      end

      describe "with component exceptions" do
        let(:exception_params) do
          full_service_params.merge(
            exceptions: {
              tires: [
                { brand: "Michelin", model: "Power" },
                { brand: "Michelin", model: "Power" }
              ]
            }
          )
        end
        let(:result) { described_class.record_maintenance(bicycle, exception_params) }

        it "applies exceptions while using defaults for other components" do
          result
          bicycle.reload
          expect(bicycle.tires).to all(have_attributes(brand: "Michelin", model: "Power", kilometres: 0.0))

          default_attributes = { brand: "Shimano", model: "105", kilometres: 0.0 }
          expect(bicycle.chain).to have_attributes(default_attributes)
          expect(bicycle.cassette).to have_attributes(default_attributes)
          expect(bicycle.chainring).to have_attributes(default_attributes)
          expect(bicycle.brakepads).to all(have_attributes(default_attributes))
        end
      end
    end

    describe "maintenance actions only" do
      let(:maintenance_action_params) do
        {
          maintenance_actions: [
            { component_type: "cassette", action_performed: "cleaned" },
            { component_type: "tire", action_performed: "checked pressure" }
          ]
        }
      end
      let(:result) { described_class.record_maintenance(bicycle, maintenance_action_params) }

      it "records maintenance actions without replacements" do
        expect { result }.to change(MaintenanceAction, :count).by(2)
        expect { result }.not_to change(ComponentReplacement, :count)
      end

      it "leaves components unchanged during maintenance actions" do
        result
        expect(chain.reload.kilometres).to eq(initial_chain_km)
        expect(cassette.reload.kilometres).to eq(initial_cassette_km)
        expect(chainring.reload.kilometres).to eq(initial_chainring_km)
        expect(tires.map { |t| t.reload.kilometres }).to eq(initial_tire_kms)
        expect(brakepads.map { |b| b.reload.kilometres }).to eq(initial_brakepad_kms)
      end

      it "creates service record for maintenance actions" do
        result
        service = Service.last
        expect(service.service_type).to eq("partial_replacement")
        expect(service.maintenance_actions.count).to eq(2)
      end
    end

    describe "mixed maintenance and replacements" do
      let(:mixed_service_params) do
        {
          notes: "Mixed service",
          replacements: { chain: { brand: "SRAM", model: "Force" } },
          maintenance_actions: [
            { component_type: "cassette", action_performed: "cleaned and lubricated" }
          ]
        }
      end
      let(:result) { described_class.record_maintenance(bicycle, mixed_service_params) }

      it "handles chain replacement correctly" do
        result
        expect(chain.reload.status).to eq("replaced")
        expect(bicycle.reload.chain.kilometres).to eq(0)
      end

      it "handles cassette maintenance correctly" do
        result
        maintenance_action = MaintenanceAction.by_component("cassette").last
        expect(maintenance_action.action_performed).to eq("cleaned and lubricated")
        expect(cassette.reload.kilometres).to eq(initial_cassette_km)
        expect(cassette.reload.status).to eq("active")
      end

      it "creates correct audit trail" do
        expect { result }.to change(ComponentReplacement, :count).by(1)
                                   .and change(MaintenanceAction, :count).by(1)

        service = Service.last
        expect(service.component_replacements.count).to eq(1)
        expect(service.maintenance_actions.count).to eq(1)
        expect(service.component_replacements.first.component_type).to eq("chain")
        expect(service.maintenance_actions.first.component_type).to eq("cassette")
      end
    end

    describe "validation errors" do
      it "raises error when default_brand missing for full service" do
        expect {
          described_class.record_maintenance(bicycle, {
            notes: "Full service",
            full_service: true,
            default_model: "105"
          })
        }.to raise_error(Api::V1::Errors::ValidationError) do |error|
          expect(error.message).to include("Default brand is required for full service")
        end
      end

      it "raises error when default_model missing for full service" do
        expect {
          described_class.record_maintenance(bicycle, {
            notes: "Full service",
            full_service: true,
            default_brand: "Shimano"
          })
        }.to raise_error(Api::V1::Errors::ValidationError) do |error|
          expect(error.message).to include("Default model is required for full service")
        end
      end
    end

    describe "error handling and rollback" do
      it "rolls back all changes on service failure" do
        initial_counts = {
          chains: Chain.count,
          services: Service.count,
          component_replacements: ComponentReplacement.count,
          maintenance_actions: MaintenanceAction.count
        }

        # Mock a failure in the middle of the service
        allow(ComponentReplacement).to receive(:create!)
          .and_raise(StandardError.new("Simulated failure"))

        expect {
          described_class.record_maintenance(bicycle, {
            notes: "Full service",
            full_service: true,
            default_brand: "Shimano",
            default_model: "105"
          })
        }.to raise_error(Api::V1::Errors::ApiError, "An unexpected error occurred during maintenance")

        # Verify rollback
        expect(Chain.count).to eq(initial_counts[:chains])
        expect(Service.count).to eq(initial_counts[:services])
        expect(ComponentReplacement.count).to eq(initial_counts[:component_replacements])
        expect(MaintenanceAction.count).to eq(initial_counts[:maintenance_actions])
      end
    end

    describe "audit trail creation" do
      it "links service to component replacements correctly" do
        described_class.record_maintenance(bicycle, {
          notes: "Multiple replacements",
          replacements: {
            chain: { brand: "SRAM", model: "Force" },
            cassette: { brand: "SRAM", model: "Force" },
            tires: [
              { brand: "Continental", model: "GP5000" },
              { brand: "Continental", model: "GP5000" }
            ]
          }
        })

        service = Service.last
        ComponentReplacement.all.each do |replacement|
          expect(replacement.service_id).to eq(service.id)
        end
        expect(service.component_replacements.count).to eq(3)
        expect(service.component_replacements.pluck(:component_type)).to contain_exactly(
          "chain", "cassette", "tire"
        )
      end

      it "links service to maintenance actions correctly" do
        described_class.record_maintenance(bicycle, {
          notes: "Multiple maintenance actions",
          maintenance_actions: [
            { component_type: "chain", action_performed: "cleaned and lubricated" },
            { component_type: "cassette", action_performed: "inspected for wear" },
            { component_type: "tire", action_performed: "checked pressure" }
          ]
        })

        service = Service.last
        MaintenanceAction.all.each do |action|
          expect(action.service_id).to eq(service.id)
        end
        expect(service.maintenance_actions.count).to eq(3)
        expect(service.maintenance_actions.pluck(:component_type)).to contain_exactly(
          "chain", "cassette", "tire"
        )
      end

      it "records service timestamp accurately" do
        request_time = Time.current
        described_class.record_maintenance(bicycle, {
          notes: "Basic service",
          maintenance_actions: [{ component_type: "chain", action_performed: "cleaned" }]
        })

        service = Service.last
        expect(service.performed_at).to be_within(1.second).of(request_time)
        expect(service.performed_at).to be_a(Time)
        expect(service.performed_at).to be <= Time.current
      end

      it "preserves complete component history" do
        original_chain_data = transform_component_to_specs(chain)

        described_class.record_maintenance(bicycle, {
          notes: "Chain replacement",
          replacements: { chain: { brand: "SRAM", model: "Force" } }
        })

        replacement = ComponentReplacement.last
        expect(replacement.old_component_specs).to eq(original_chain_data)
        expect(replacement.new_component_specs).to eq({
          "brand" => "SRAM", "model" => "Force", "status" => "active"
        })
        expect(replacement.component_type).to eq("chain")
        expect(replacement.reason).to include("Component replacement")
      end
    end
  end

  private

  def transform_components_to_specs(components)
    Array(components).map { |component| transform_component_to_specs(component) }
  end

  def transform_component_to_specs(component)
    {
      "brand" => component.brand,
      "model" => component.model,
      "kilometres" => component.kilometres,
      "status" => component.status
    }
  end
end