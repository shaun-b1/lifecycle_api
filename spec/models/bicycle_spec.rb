require 'rails_helper'

RSpec.describe Bicycle, type: :model do
  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }
  describe "wear limits calculation" do
    describe "base limits" do
      it "calculates base wear limits correctly" do
        limits = bicycle.base_wear_limits

        expect(limits).to eq({
          chain: 3500,
          cassette: 10000,
          chainring: 18000,
          tire: 5500,
          brakepad: 4000
        })
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
          let (:mountain_biker_bike) { create(:bicycle, user: user, terrain: "mountainous", weather: 'mixed', particulate: 'medium') }
          let (:commuter_bike) { create(:bicycle, user: user, terrain: "flat", weather: 'dry', particulate: 'high') }
          let (:weekend_cyclist_bike) { create(:bicycle, user: user, terrain: "hilly", weather: 'mixed', particulate: 'low') }

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
    it "identifies components approaching wear limits" do
      # bicycle with high-mileage chain suggests "Chain needs replacement"
      # bicycle with high-mileage brakes suggests "Brake pad X needs inspection"
      # bicycle with multiple worn components returns multiple recommendations
    end

    it "handles missing components gracefully" do
      # bicycle with no chain doesn't crash, returns empty array
      # bicycle with only some components gives appropriate recommendations
    end

    it "considers environmental factors in recommendations" do
      # mountainous bike recommends replacement sooner than flat bike
    end

    it "provides no recommendations for new components" do
      # fresh bicycle returns empty recommendations array
    end
  end

  describe "component status" do
    it "calculates wear percentages correctly" do
      # component at 50% of limit shows 50% wear
      # component at 100% of limit shows 100% wear
      # component at 0km shows 0% wear
    end

    it "handles missing components without crashing" do
      # bicycle with no chain returns nil for chain status
      # bicycle with some components returns partial status
    end
    it "includes bicycle summary information" do
      # status includes bicycle kilometres, lifetime kilometres, environment
    end
    it "handles edge cases in wear calculation" do
      # components with zero limits don't cause division by zero
      # negative kilometres don't break percentage calculation
    end
    it "shows environmental impact in status summary" do
      # mountainous bike shows lower wear limits than flat bike
    end
  end
end
