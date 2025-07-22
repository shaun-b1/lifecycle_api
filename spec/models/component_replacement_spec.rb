require "rails_helper"

RSpec.describe ComponentReplacement, type: :model do
  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }
  let(:service) { create(:service, bicycle: bicycle) }
  let(:component_replacement) { build(:component_replacement, service: service) }

  describe "validations" do
    it "valid with all required attributes" do
      expect(component_replacement).to be_valid
    end

    it "requires component_type" do
      component_replacement.component_type = nil

      expect(component_replacement).to be_invalid
      expect(component_replacement.errors[:component_type]).to be_present
    end

    it "validates component_type inclusion" do
      component_replacement.component_type = "invalid_type"

      expect(component_replacement).to be_invalid
      expect(component_replacement.errors[:component_type]).to include("must be a valid component type")
    end

    it "requires reason" do
      component_replacement.reason = nil

      expect(component_replacement).to be_invalid
      expect(component_replacement.errors[:reason]).to include("can't be blank")
    end

    it "requires new_component_specs" do
      component_replacement.new_component_specs = nil

      expect(component_replacement).to be_invalid
      expect(component_replacement.errors[:new_component_specs]).to be_present
    end

    it "allows nil old_component_specs" do
      component_replacement.old_component_specs = nil

      expect(component_replacement).to be_valid
    end
  end

  describe "scopes" do
    let!(:chain_replacement) { create(:component_replacement, :chain_replacement) }
    let!(:tire_replacement) { create(:component_replacement, :tire_replacement) }
    let!(:old_replacement) { create(:component_replacement, service: create(:service, :old_service)) }
    let!(:recent_replacement) { create(:component_replacement, service: create(:service, :recent_service)) }

    describe ".by_component" do
      it "filters by component_type" do
        result = ComponentReplacement.by_component("chain")

        expect(result).to include(chain_replacement)
        expect(result).not_to include(tire_replacement)
      end

      it "returns empty when no matches" do
        result = ComponentReplacement.by_component("nonexistent")

        expect(result).to be_empty
      end
    end

    describe ".recent" do
      it "orders by service performed_at desc" do
        result = ComponentReplacement.recent
        service_dates = result.joins(:service).pluck('services.performed_at')

        expect(service_dates).to eq(service_dates.sort.reverse)
      end
    end
  end

  describe "instance methods" do
    describe "#old_kilometres" do
      it "returns kilometres from old_component_specs hash" do
        component_replacement.old_component_specs = { brand: "Old", kilometres: 2500 }

        expect(component_replacement.old_kilometres).to eq(2500)
      end

      it "returns 0 when old_component_specs is nil" do
        component_replacement.old_component_specs = nil

        expect(component_replacement.old_kilometres).to eq(0)
      end

      it "returns 0 when kilometres not in old_component_specs" do
        component_replacement.old_component_specs = { brand: "Old" }

        expect(component_replacement.old_kilometres).to eq(0)
      end

      it "handles multiple components array format" do
        component_replacement.old_component_specs = [
          { brand: "Front", kilometres: 1000 },
          { brand: "Rear", kilometres: 1500 }
        ]

        expect(component_replacement.old_kilometres).to eq(1500)
      end
    end

    describe "#brand_changed?" do
      it "returns true when brands are different" do
        component_replacement.old_component_specs = { brand: "Shimano" }
        component_replacement.new_component_specs = { brand: "SRAM" }

        expect(component_replacement.brand_changed?).to be true
      end

      it "returns false when brands are same" do
        component_replacement.old_component_specs = { brand: "Shimano" }
        component_replacement.new_component_specs = { brand: "Shimano" }

        expect(component_replacement.brand_changed?).to be false
      end

      it "returns false when old_component_specs is nil" do
        component_replacement.old_component_specs = nil
        component_replacement.new_component_specs = { brand: "Shimano" }

        expect(component_replacement.brand_changed?).to be false
      end

      it "handles array format old_component_specs" do
        component_replacement.old_component_specs = [ { brand: "Shimano" } ]
        component_replacement.new_component_specs = { brand: "SRAM" }

        expect(component_replacement.brand_changed?).to be true
      end

      it "returns false when new_component_specs is nil" do
        component_replacement.old_component_specs = { brand: "Shimano" }
        component_replacement.new_component_specs = nil

        expect(component_replacement.brand_changed?).to be false
      end
    end

    describe "#replacement_summary" do
      it "generates summary for brand change" do
        component_replacement.component_type = "chain"
        component_replacement.old_component_specs = { brand: "Shimano" }
        component_replacement.new_component_specs = { brand: "SRAM" }

        expect(component_replacement.replacement_summary).to eq("Chain: Shimano → SRAM")
      end

      it "handles missing old component specs" do
        component_replacement.component_type = "cassette"
        component_replacement.old_component_specs = nil
        component_replacement.new_component_specs = { brand: "Campagnolo" }

        expect(component_replacement.replacement_summary).to eq("Cassette: Unknown → Campagnolo")
      end

      it "handles array format specs" do
        component_replacement.component_type = "tire"
        component_replacement.old_component_specs = [ { brand: "Continental" } ]
        component_replacement.new_component_specs = [ { brand: "Michelin" } ]

        expect(component_replacement.replacement_summary).to eq("Tire: Continental → Michelin")
      end
    end
  end
end
