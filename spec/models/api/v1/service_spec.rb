require 'rails_helper'

RSpec.describe Api::V1::Service, type: :model do
  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }
  let(:service) { build(:service, bicycle: bicycle) }

  describe "validations" do
    it "valid with all required attributes" do
      expect(service).to be_valid
    end

    it "requires performed_at" do
      service.performed_at = nil

      expect(service).to be_invalid
      expect(service.errors[:performed_at]).to be_present
    end

    it "requires notes" do
      service.notes = nil

      expect(service).to be_invalid
      expect(service.errors[:notes]).to be_present
    end

    it "requires notes to not be blank" do
      service.notes = ""

      expect(service).to be_invalid
      expect(service.errors[:notes]).to be_present
    end

    it "validates service_type inclusion" do
      service.service_type = "invalid_type"

      expect(service).to be_invalid
      expect(service.errors[:service_type]).to be_present
      expect(service.errors[:service_type]).to include("must be a valid service type")
    end

    it "accepts valid service_types" do
      valid_types = [ "full_service", "partial_replacement", "tune_up", "emergency_repair", "inspection" ]

      valid_types.each do |type|
        test_service = build(:service, bicycle: bicycle, service_type: type)
        expect(test_service).to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:old_service) { create(:service, bicycle: bicycle, performed_at: 1.month.ago) }
    let!(:recent_service) { create(:service, bicycle: bicycle, performed_at: 1.day.ago) }
    let!(:tune_up_service) { create(:service, bicycle: bicycle, service_type: "tune_up") }
    let!(:full_service) { create(:service, bicycle: bicycle, service_type: "full_service") }

    it "recent scope orders by performed_at desc" do
      result = Api::V1::Service.recent
      timestamps = result.pluck(:performed_at)

      expect(timestamps).to eq(timestamps.sort.reverse)
    end

    it "by_type scope filters by service_type" do
      result = Api::V1::Service.by_type("tune_up")

      expect(result).to include(tune_up_service)
      expect(result).not_to include(full_service)
    end

    it "this_year scope filters to current year" do
      last_year_service = create(:service, bicycle: bicycle, performed_at: 1.year.ago)
      result = Api::V1::Service.this_year

      expect(result).to include(recent_service)
      expect(result).not_to include(last_year_service)
    end
  end

  describe "instance methods" do
    describe "#full_service?" do
      it "returns true for full_service type" do
        service.service_type = "full_service"
        expect(service.full_service?).to be true
      end

      it "returns false for other types" do
        service.service_type = "tune_up"
        expect(service.full_service?).to be false
      end
    end

    describe "#components_replaced" do
      it "lists unique component types" do
        service.save!
        create(:component_replacement, service: service, component_type: "chain")
        create(:component_replacement, service: service, component_type: "cassette")

        result = service.components_replaced
        expect(result).to include("chain", "cassette")
        expect(result.length).to eq(2)
      end

      it "deduplicates multiple components of same type" do
        service.save!
        create(:component_replacement, service: service, component_type: "tire")
        create(:component_replacement, service: service, component_type: "tire")

        result = service.components_replaced
        expect(result).to eq([ "tire" ])
      end

      it "returns empty array when no replacements exist" do
        service.save!
        expect(service.components_replaced).to be_empty
      end
    end
  end

  describe "edge cases" do
    it "allows future scheduled maintenance" do
      service.performed_at = 2.weeks.from_now
      expect(service).to be_valid
    end

    it "handles service on bicycle's creation day" do
      service.performed_at = bicycle.created_at + 1.hour
      expect(service).to be_valid
    end

    it "validates comprehensive maintenance notes" do
      detailed_notes = "A" * 2000  # Very long notes
      service.notes = detailed_notes
      expect(service).to be_valid
    end

    it "allows service type changes" do
      service.service_type = "partial_replacement"
      service.save!
      service.service_type = "full_service"
      expect(service).to be_valid
    end
  end
end
