require "rails_helper"

RSpec.describe Api::V1::MaintenanceAction, type: :model do
  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }
  let(:service) { create(:service, bicycle: bicycle) }
  let(:maintenance_action) { build(:maintenance_action, service: service) }

  describe "validations" do
    it "valid with all required attributes" do
      expect(maintenance_action).to be_valid
    end

    it "requires component_type" do
      maintenance_action.component_type = nil

      expect(maintenance_action).to be_invalid
      expect(maintenance_action.errors[:component_type]).to be_present
    end

    it "requires action_performed" do
      maintenance_action.action_performed = nil

      expect(maintenance_action).to be_invalid
      expect(maintenance_action.errors[:action_performed]).to be_present
    end
  end

  describe "scopes" do
    let!(:chain_action) { create(:maintenance_action, component_type: "chain") }
    let!(:tire_action) { create(:maintenance_action, component_type: "tire") }

    describe ".by_component" do
      it "filters by component_type" do
        result = Api::V1::MaintenanceAction.by_component("chain")

        expect(result).to include(chain_action)
        expect(result).not_to include(tire_action)
      end

      it "returns empty when no matches" do
        result = Api::V1::MaintenanceAction.by_component("nonexistent")

        expect(result).to be_empty
      end
    end
  end

  describe "instance methods" do
    describe "#action_summary" do
      it "generates formatted summary" do
        maintenance_action.component_type = "chain"
        maintenance_action.action_performed = "cleaned and lubricated"

        expect(maintenance_action.action_summary).to eq("Chain: cleaned and lubricated")
      end

      it "handles different component types" do
        maintenance_action.component_type = "tire"
        maintenance_action.action_performed = "checked pressure"

        expect(maintenance_action.action_summary).to eq("Tire: checked pressure")
      end

      it "humanizes component_type correctly" do
        maintenance_action.component_type = "brakepad"
        maintenance_action.action_performed = "inspected wear"

        expect(maintenance_action.action_summary).to eq("Brakepad: inspected wear")
      end
    end
  end
end
