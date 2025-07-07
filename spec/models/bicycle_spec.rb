require 'rails_helper'

RSpec.describe Bicycle, type: :model do
  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }
  describe "wear limits calculation" do
    describe "base limits" do
      it "calculates base wear limits correctly" do
        limits = bicycle.base_wear_limits

        expect(limits).to eq({
          chain:     3500,
          cassette:  10000,
          chainring: 18000,
          tire:      5500,
          brakepad:  4000 })
      end
    end

    describe "environmental factors" do
      describe "terrain impact on cycling components" do
        let (:mountainous_bike) { create(:bicycle, user: user, terrain: 'mountainous') }
        let (:flat_bike) { create(:bicycle, user: user, terrain: 'flat') }

        let (:flat_multipliers) { flat_bike.wear_multipliers }
        let (:mountainous_multipliers) { mountainous_bike.wear_multipliers }
        it "affects braking components most severely on steep terrain" do
            flat_brakes = flat_multipliers[:brakepad]
            mountainous_brakes = mountainous_multipliers[:brakepad]
            mountainous_chain = mountainous_multipliers[:chain]

            brake_increase = mountainous_brakes - flat_brakes
            chain_increase = mountainous_chain - flat_multipliers[:chain]

            expect(brake_increase).to be > chain_increase,
              "Brakes should wear faster than drivetrain on steep terrain due to heavy descending"
        end
        it "moderately increases drivetrain component wear on challenging terrain" do
          drivetrain_components = [ :chain, :cassette, :chainring ]

          drivetrain_components.each do |component|
            flat_wear = flat_multipliers[component]
            mountainous_wear = mountainous_multipliers[component]

            expect(mountainous_wear).to be > flat_wear,
              "#{component} should have moderate increase on challenging terrain"
          end
        end

        it "has minimal impact on tire wear patterns" do
          flat_tire = flat_multipliers[:tire]
          mountainous_tire = mountainous_multipliers[:tire]

          expect(mountainous_tire).to be_within(0.2).of(flat_tire),
            "Tire wear should be minimally affected by terrain difficulty"
        end

        it "follows realistic cycling wear patterns" do
          brake_impact = mountainous_multipliers[:brakepad] - flat_multipliers[:brakepad]
          chain_impact = mountainous_multipliers[:chain] - flat_multipliers[:chain]
          tire_impact = mountainous_multipliers[:tire] - flat_multipliers[:tire]

          expect(brake_impact).to be > chain_impact
          expect(chain_impact).to be > tire_impact
          expect(tire_impact).to be >= 0
        end
      end

      describe "weather impact on cycling components" do
        let (:wet_bike) { create(:bicycle, user: user, weather: 'wet') }
        let (:dry_bike) { create(:bicycle, user: user, weather: 'dry') }

        let (:wet_multipliers) { wet_bike.wear_multipliers }
        let (:dry_multipliers) { dry_bike.wear_multipliers }

        it "increases exposed component wear with wet weather" do
          drivetrain_components = [ :chain, :cassette, :chainring, :brakepad ]

          drivetrain_components.each do |component|
            dry_wear = dry_multipliers[component]
            wet_wear = wet_multipliers[component]

            expect(wet_wear).to be > dry_wear,
              "#{component} should have increased wear in challenging conditions"
          end
        end

        it "has minimal impact on tire wear patterns" do
          dry_tire = dry_multipliers[:tire]
          wet_tire = wet_multipliers[:tire]

          expect(wet_tire).to be_within(0.2).of(dry_tire),
            "Tire wear should be minimally affected by terrain difficulty"
        end

        it "follows realistic cycling wear patterns" do
          brake_impact = wet_multipliers[:brakepad] - dry_multipliers[:brakepad]
          chain_impact = wet_multipliers[:chain] - dry_multipliers[:chain]
          tire_impact = wet_multipliers[:tire] - dry_multipliers[:tire]

          expect(brake_impact).to be_within(0.1).of(chain_impact)
          expect(chain_impact).to be > tire_impact
          expect(tire_impact).to be >= 0
        end
      end

      describe "particulate impact on cycling components" do
        let (:low_particulate_bike) { create(:bicycle, user: user, particulate: 'low') }
        let (:high_particulate_bike) { create(:bicycle, user: user, particulate: 'high') }

        let (:low_particulate_multipliers) { low_particulate_bike.wear_multipliers }
        let (:high_particulate_multipliers) { high_particulate_bike.wear_multipliers }

        it "increases exposed component wear with high particulate" do
          drivetrain_components = [ :chain, :cassette, :chainring, :brakepad ]

          drivetrain_components.each do |component|
            low_particulate_wear = low_particulate_multipliers[component]
            high_particulate_wear = high_particulate_multipliers[component]

            expect(high_particulate_wear).to be > low_particulate_wear,
              "#{component} should have increased wear in high particulate environments"
          end
        end

        it "has minimal impact on tire wear patterns" do
          low_particulate_tire = low_particulate_multipliers[:tire]
          high_particulate_tire = high_particulate_multipliers[:tire]

          expect(high_particulate_tire).to be_within(0.2).of(low_particulate_tire),
            "Tire wear should be minimally affected by particulate"
        end

        it "follows realistic cycling wear patterns" do
          brake_impact = high_particulate_multipliers[:brakepad] - low_particulate_multipliers[:brakepad]
          chain_impact = high_particulate_multipliers[:chain] - low_particulate_multipliers[:chain]
          tire_impact = high_particulate_multipliers[:tire] - low_particulate_multipliers[:tire]

          expect(brake_impact).to be < chain_impact
          expect(chain_impact).to be > tire_impact
          expect(tire_impact).to be >= 0
        end
      end

      describe "multiple environmental factor impact on cycling components" do
        it "multiple harsh factors compound wear" do
          low_wear_bike = create(:bicycle, user: user, terrain: "flat", weather: 'dry', particulate: 'low')
          high_wear_bike = create(:bicycle, user: user, terrain: "mountainous", weather: 'wet', particulate: 'high')

          components = [ :chain, :cassette, :brakepad, :tire, :chainring ]

          components.each do |component|
            low_wear_component = low_wear_bike.wear_multipliers[component]
            high_wear_component = high_wear_bike.wear_multipliers[component]

            expect(high_wear_component).to be > low_wear_component,
              "#{component} should have increased wear in high wear conditions"
          end
        end

        context "realistic scenarios" do
          let (:mountain_biker_bike) {
 create(:bicycle, user: user, terrain: "mountainous", weather: 'mixed', particulate: 'medium') }
          let (:commuter_bike) { create(:bicycle, user: user, terrain: "flat", weather: 'dry', particulate: 'high') }
          let (:weekend_cyclist_bike) {
 create(:bicycle, user: user, terrain: "hilly", weather: 'mixed', particulate: 'low') }

          let (:mountain_biker_multipliers) { mountain_biker_bike.wear_multipliers }
          let (:commuter_multipliers) { commuter_bike.wear_multipliers }
          let (:weekend_cyclist_multipliers) { weekend_cyclist_bike.wear_multipliers }

          it "models realistic component wear patterns for different cycling styles" do
            mountain_biker_brakes = mountain_biker_multipliers[:brakepad]
            commuter_brakes = commuter_multipliers[:brakepad]
            expect(mountain_biker_brakes).to be > commuter_brakes

            mountain_chain = mountain_biker_multipliers[:chain]
            weekend_chain = weekend_cyclist_multipliers[:chain]
            commuter_chain = commuter_multipliers[:chain]
            expect(mountain_chain).to be > commuter_chain
            expect(commuter_chain).to be > weekend_chain

            expect(mountain_biker_bike.adjusted_wear_limits[:chain]).to be > 500
            expect(commuter_bike.adjusted_wear_limits[:brakepad]).to be > 1000
          end
        end
        it "still returns reasonable limits on component wear" do
          low_wear_bike = create(:bicycle, user: user, terrain: "flat", weather: 'dry', particulate: 'low')
          high_wear_bike = create(:bicycle, user: user, terrain: "mountainous", weather: 'wet', particulate: 'high')

          low_wear_limits = low_wear_bike.adjusted_wear_limits
          high_wear_limits = high_wear_bike.adjusted_wear_limits
          base_limits = high_wear_bike.base_wear_limits

          expect(high_wear_limits.values).to all(be > 0)

          expect(high_wear_limits[:chain]).to be > 500
          expect(high_wear_limits[:brakepad]).to be > 200
          expect(high_wear_limits[:cassette]).to be > 1000
          expect(high_wear_limits[:chainring]).to be > 2000
          expect(high_wear_limits[:tire]).to be > 1000

          expect(low_wear_limits[:chain]).to be_within(100).of(base_limits[:chain])

          expect(high_wear_limits[:chain]).to be < (low_wear_limits[:chain] * 0.8)
          expect(high_wear_limits[:chain]).to be > (low_wear_limits[:chain] * 0.2)
        end
      end
    end
  end

  describe "maintenance recommendations" do
    it "recommends single instance component inspection" do
      create(:chain, bicycle: bicycle, kilometres: 3600)

      recommendations = bicycle.maintenance_recommendations
      expect(recommendations).to include("Chain needs replacement")
    end

    it "recommends inspection for dual components like brake pads" do
      create(:brakepad, bicycle: bicycle, kilometres: 4100)

      recommendations = bicycle.maintenance_recommendations
      expect(recommendations).to include("Brake pad 1 needs inspection")
    end

    it "recommends multiple component inspection" do
      create(:chain, bicycle: bicycle, kilometres: 3600)
      create(:brakepad, bicycle: bicycle, kilometres: 4100)

      recommendations = bicycle.maintenance_recommendations
      expect(recommendations).to include("Brake pad 1 needs inspection", "Chain needs replacement")
    end

    it "handles missing components gracefully" do
      empty_recommendations = bicycle.maintenance_recommendations
      expect(empty_recommendations).to eq([])

      create(:chain, bicycle: bicycle, kilometres: 3600)
      create(:brakepad, bicycle: bicycle, kilometres: 3600)
      create(:brakepad, bicycle: bicycle, kilometres: 3600)
      create(:chainring, bicycle: bicycle, kilometres: 3600)
      create(:cassette, bicycle: bicycle, kilometres: 3600)
      partial_recommendations = bicycle.maintenance_recommendations
      expect(partial_recommendations).to eq([ "Chain needs replacement" ])
    end

    it "considers environmental factors in recommendations" do
        wet_bike = create(:bicycle, user: user, weather: 'wet')
        dry_bike = create(:bicycle, user: user, weather: 'dry')

        create(:chain, bicycle: wet_bike, kilometres: 3000)
        create(:chain, bicycle: dry_bike, kilometres: 3000)

        wet_recommendations = wet_bike.maintenance_recommendations
        dry_recommendations = dry_bike.maintenance_recommendations

        expect(wet_recommendations).to include("Chain needs replacement")
        expect(dry_recommendations).to be_empty
    end

    it "provides no recommendations for new components" do
      create(:chain, bicycle: bicycle, kilometres: 0)
      create(:brakepad, bicycle: bicycle, kilometres: 0)
      create(:brakepad, bicycle: bicycle, kilometres: 0)
      create(:chainring, bicycle: bicycle, kilometres: 0)
      create(:cassette, bicycle: bicycle, kilometres: 0)
      create(:tire, bicycle: bicycle, kilometres: 0)
      create(:tire, bicycle: bicycle, kilometres: 0)

      recommendations = bicycle.maintenance_recommendations

      expect(recommendations).to be_empty
    end
  end

  describe "component status" do
    it "calculates wear percentages correctly" do
      test_cases = [
        { kilometres: 0, expected: 0 },
        { kilometres: 1750, expected: 50 },
        { kilometres: 3500, expected: 100 }
      ]

      test_cases.each do |test_case|
        bike = create(:bicycle, user: user)
        create(:chain, bicycle: bike, kilometres: test_case[:kilometres])
        expect(bike.component_status[:chain][:wear_percentage]).to eq(test_case[:expected])
      end
    end

    it "handles missing components without crashing" do
      create(:chainring, bicycle: bicycle, kilometres: 0)
      create(:cassette, bicycle: bicycle, kilometres: 0)

      bike_status = bicycle.component_status

      expect(bike_status[:chain]).to be_nil
      expect(bike_status[:chainring][:wear_percentage]).to eq(0)
      expect(bike_status[:cassette][:wear_percentage]).to eq(0)
    end
    it "includes bicycle summary information" do
      bicycle = create(:bicycle, user: user, kilometres: 0, terrain: 'mountainous', weather: 'mixed',
particulate: 'low')
      bike_status = bicycle.component_status

      expect(bike_status[:bicycle][:kilometres]).to eq(0)
      expect(bike_status[:bicycle][:lifetime_kilometres]).to eq(0)
      expect(bike_status[:bicycle][:riding_environment][:terrain]).to eq("Mountainous terrain")
      expect(bike_status[:bicycle][:riding_environment][:weather]).to eq("Mixed weather conditions")
      expect(bike_status[:bicycle][:riding_environment][:particulate]).to eq("Low particulate")
    end
    it "handles edge cases in wear calculation" do
      bicycle = create(:bicycle, user: user, terrain: 'mountainous', weather: 'wet', particulate: 'high')
      create(:chain, bicycle: bicycle, kilometres: 2000)
      bike_status = bicycle.component_status

      expect { bike_status }.not_to raise_error
      expect(bike_status[:chain][:wear_percentage]).to be >= 0
      expect(bike_status[:chain][:wear_percentage]).to be > 100
    end
    it "shows environmental impact in status summary" do
        wet_bike = create(:bicycle, user: user, weather: 'wet')
        dry_bike = create(:bicycle, user: user, weather: 'dry')

        create(:chain, bicycle: wet_bike)
        create(:chain, bicycle: dry_bike)

        wet_status = wet_bike.component_status
        dry_status = dry_bike.component_status

        expect(wet_status[:chain][:wear_limit]).to be < (dry_status[:chain][:wear_limit])
    end
  end
end
