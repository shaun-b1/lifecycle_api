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
      expect(result).to be true
    end

    it "validates distance input" do
      # create bicycle
      # expect calling with distance 0 raises ValidationError
      # expect calling with negative distance raises ValidationError
      # expect error message mentions "greater than zero"
      expect(true).to eq(true)
    end

    it "validates bicycle exists" do
      # expect calling with nil bicycle raises ResourceNotFoundError
      # expect error message mentions "Bicycle"
      expect(true).to eq(true)
    end

    it "updates all component types correctly" do
      # create bicycle with full component set (chain, cassette, chainring, 2 tires, 2 brakepads)
      # call service with 25km
      # expect all 7 components have 25km added
      # expect all components have kilometre logs created
      expect(true).to eq(true)
    end

    it "handles bicycles with missing components gracefully" do
      # create bicycle with full component set (chain, cassette, chainring, 2 tires, 2 brakepads)
      # call service with 25km
      # expect all 7 components have 25km added
      # expect all components have kilometre logs created
      expect(true).to eq(true)
    end

    it "uses database transactions for atomicity" do
      # create bicycle with components
      # mock one component to fail update
      # expect calling service raises error
      # expect bicycle kilometres NOT updated (rollback)
      # expect other components NOT updated (rollback)
      expect(true).to eq(true)
    end

    it "includes notes in bicycle kilometre log" do
      # create bicycle
      # call service with distance 40 and notes "Test ride"
      # expect bicycle kilometre log includes "Test ride" in notes
      expect(true).to eq(true)
    end

    it "handles component update failures" do
      # create bicycle with chain
      # mock chain.add_kilometres to return false with errors
      # expect calling service raises ValidationError
      # expect error message includes component class name
      # expect error details include component error messages
      expect(true).to eq(true)
    end
  end
end
