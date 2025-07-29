class Api::V1::BicycleWearCalculator
  def initialize(riding_environment)
    @riding_environment = riding_environment
  end

  def base_wear_limits
    {
      chain: 3500,
      cassette: 10000,
      chainring: 18000,
      tire: 5500,
      brakepad: 4000
    }
  end

  def wear_multipliers
    multipliers = { chain: 1.0, cassette: 1.0, chainring: 1.0, tire: 1.0, brakepad: 1.0 }

    apply_terrain_multipliers(multipliers)
    apply_weather_multipliers(multipliers)
    apply_particulate_multipliers(multipliers)

    multipliers
  end

  def adjusted_wear_limits
    base = base_wear_limits
    mults = wear_multipliers

    {
      chain: (base[:chain] / mults[:chain]).round,
      cassette: (base[:cassette] / mults[:cassette]).round,
      chainring: (base[:chainring] / mults[:chainring]).round,
      tire: (base[:tire] / mults[:tire]).round,
      brakepad: (base[:brakepad] / mults[:brakepad]).round
    }
  end

  private

  attr_reader :riding_environment

  def apply_terrain_multipliers(multipliers)
    case riding_environment.terrain
    when "hilly"
      multipliers[:chain] *= 1.2
      multipliers[:cassette] *= 1.3
      multipliers[:chainring] *= 1.2
      multipliers[:tire] *= 1.1
      multipliers[:brakepad] *= 1.5
    when "mountainous"
      multipliers[:chain] *= 1.4
      multipliers[:cassette] *= 1.6
      multipliers[:chainring] *= 1.4
      multipliers[:tire] *= 1.2
      multipliers[:brakepad] *= 2.0
    end
  end

  def apply_weather_multipliers(multipliers)
    case riding_environment.weather
    when "mixed"
      multipliers[:chain] *= 1.2
      multipliers[:cassette] *= 1.1
      multipliers[:chainring] *= 1.1
      multipliers[:brakepad] *= 1.2
    when "wet"
      multipliers[:chain] *= 1.5
      multipliers[:cassette] *= 1.3
      multipliers[:chainring] *= 1.2
      multipliers[:brakepad] *= 1.5
    end
  end

  def apply_particulate_multipliers(multipliers)
    case riding_environment.particulate
    when "medium"
      multipliers[:chain] *= 1.3
      multipliers[:cassette] *= 1.2
      multipliers[:chainring] *= 1.1
      multipliers[:tire] *= 1.1
    when "high"
      multipliers[:chain] *= 1.6
      multipliers[:cassette] *= 1.4
      multipliers[:chainring] *= 1.3
      multipliers[:tire] *= 1.2
      multipliers[:brakepad] *= 1.3
    end
  end
end