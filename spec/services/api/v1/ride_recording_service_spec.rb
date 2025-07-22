require 'rails_helper'

RSpec.describe Api::V1::RideRecordingService, type: :service do
  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user, kilometres: 0) }

  describe ".record" do
    it "successfully records ride with valid inputs" do
      chain = create(:chain, bicycle: bicycle, kilometres: 0)
      chainring = create(:chainring, bicycle: bicycle, kilometres: 0)
      cassette = create(:cassette, bicycle: bicycle, kilometres: 0)
      tire1 = create(:tire, bicycle: bicycle, kilometres: 0)
      tire2 = create(:tire, bicycle: bicycle, kilometres: 0)
      brake1 = create(:brakepad, bicycle: bicycle, kilometres: 0)
      brake2 = create(:brakepad, bicycle: bicycle, kilometres: 0)

      result = nil
      expect {
        result = Api::V1::RideRecordingService.record(bicycle, 50.0, "Morning Ride")
      }.to change { bicycle.reload.kilometres }.from(0).to(50.0)
        .and change { chain.reload.kilometres }.from(0).to(50.0)
        .and change { chainring.reload.kilometres }.from(0).to(50.0)
        .and change { cassette.reload.kilometres }.from(0).to(50.0)
        .and change { tire1.reload.kilometres }.from(0).to(50.0)
        .and change { tire2.reload.kilometres }.from(0).to(50.0)
        .and change { brake1.reload.kilometres }.from(0).to(50.0)
        .and change { brake2.reload.kilometres }.from(0).to(50.0)
        .and change { Api::V1::KilometreLog.count }.by(8)
      expect(result).to be true
    end

    it "validates distance input" do
      expect {
        Api::V1::RideRecordingService.record(bicycle, 0, "Morning Ride")
      }.to raise_error(Api::V1::Errors::ValidationError, "Ride distance must be greater than zero")

      expect {
        Api::V1::RideRecordingService.record(bicycle, -50.0, "Morning Ride")
      }.to raise_error(Api::V1::Errors::ValidationError, "Ride distance must be greater than zero")
    end

    it "validates bicycle exists" do
      expect {
        Api::V1::RideRecordingService.record(nil, 50.0, "Morning Ride")
      }.to raise_error(Api::V1::Errors::ResourceNotFoundError, "Bicycle not found")
    end

    it "handles bicycles with missing components gracefully" do
      chain = create(:chain, bicycle: bicycle, kilometres: 0)
      chainring = create(:chainring, bicycle: bicycle, kilometres: 0)
      cassette = create(:cassette, bicycle: bicycle, kilometres: 0)
      tire1 = create(:tire, bicycle: bicycle, kilometres: 0)
      brake1 = create(:brakepad, bicycle: bicycle, kilometres: 0)

      result = nil
      expect {
        result = Api::V1::RideRecordingService.record(bicycle, 50.0, "Morning Ride")
      }.to change { bicycle.reload.kilometres }.from(0).to(50.0)
        .and change { chain.reload.kilometres }.from(0).to(50.0)
        .and change { chainring.reload.kilometres }.from(0).to(50.0)
        .and change { cassette.reload.kilometres }.from(0).to(50.0)
        .and change { tire1.reload.kilometres }.from(0).to(50.0)
        .and change { brake1.reload.kilometres }.from(0).to(50.0)
        .and change { Api::V1::KilometreLog.count }.by(6)
      expect(result).to be true
    end

    it "uses database transactions for atomicity" do
      chain = create(:chain, bicycle: bicycle, kilometres: 0, status: "active")
      cassette = create(:cassette, bicycle: bicycle, kilometres: 0, status: "active")
      tire = create(:tire, bicycle: bicycle, kilometres: 0, status: "active")

      allow(bicycle).to receive(:chain).and_return(chain)
      allow(chain).to receive(:add_kilometres).and_return(false)
      allow(chain).to receive(:errors).and_return(
        double(full_messages: [ "Simulated failure" ])
      )

      expect {
        Api::V1::RideRecordingService.record(bicycle, 50.0, "Test ride")
      }.to raise_error(Api::V1::Errors::ValidationError, "Failed to update chain kilometres")

      expect(bicycle.reload.kilometres).to eq(0)
      expect(cassette.reload.kilometres).to eq(0)
      expect(tire.reload.kilometres).to eq(0)
    end

    it "includes notes in bicycle kilometre log" do
      Api::V1::RideRecordingService.record(bicycle, 50.0, "Test ride")
      result = bicycle.kilometre_logs.order(:created_at).last
      expect(result.notes).to eq("Test ride")
    end

    it "handles component update failures" do
      chain = create(:chain, bicycle: bicycle, kilometres: 0, status: "active")

      allow(bicycle).to receive(:chain).and_return(chain)
      allow(chain).to receive(:add_kilometres).and_return(false)
      allow(chain).to receive(:errors).and_return(
        double(full_messages: [ "Brand can't be blank", "Kilometres must be positive" ])
      )

      expect {
        Api::V1::RideRecordingService.record(bicycle, 50.0, "Test ride")
      }.to raise_error(Api::V1::Errors::ValidationError) do |error|
        expect(error.message).to include("Failed to update chain")
        expect(error.details).to include("Brand can't be blank")
        expect(error.details).to include("Kilometres must be positive")
      end
    end
  end
end
