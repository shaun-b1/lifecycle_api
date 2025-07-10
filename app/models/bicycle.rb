class Bicycle < ApplicationRecord
  include KilometreValidatable
  include KilometreTrackable

  belongs_to :user

  has_one :chain, -> { where(status: "active") }, dependent: :destroy
  has_one :cassette, -> { where(status: "active") }, dependent: :destroy
  has_one :chainring, -> { where(status: "active") }, dependent: :destroy
  has_many :tires, -> { where(status: "active") }, dependent: :destroy
  has_many :brakepads, -> { where(status: "active") }, dependent: :destroy

  has_many :all_chains, class_name: "Chain"
  has_many :all_cassettes, class_name: "Cassette"
  has_many :all_chainrings, class_name: "Chainring"
  has_many :all_tires, class_name: "Tire"
  has_many :all_brakepads, class_name: "Brakepad"

  validates :name, presence: true
  validates :brand, presence: true
  validates :model, presence: true
  validates :terrain, inclusion: { in: %w[flat hilly mountainous], allow_nil: true }
  validates :weather, inclusion: { in: %w[dry mixed wet], allow_nil: true }
  validates :particulate, inclusion: { in: %w[low medium high], allow_nil: true }

  def create_chain(attributes)
    all_chains.create(attributes)
  end

  def create_cassette(attributes)
    all_cassettes.create(attributes)
  end

  def create_chainring(attributes)
    all_chainrings.create(attributes)
  end

  def create_tire(attributes)
    all_tires.create(attributes)
  end

  def create_brakepad(attributes)
    all_brakepads.create(attributes)
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

    case terrain
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
      multipliers[:tire] *= 1.3
      multipliers[:brakepad] *= 2.0
    end

    case weather
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

    case particulate
    when "medium"
      multipliers[:chain] *= 1.3
      multipliers[:cassette] *= 1.2
      multipliers[:chainring] *= 1.1
      multipliers[:tire] *= 1.2
    when "high"
      multipliers[:chain] *= 1.6
      multipliers[:cassette] *= 1.4
      multipliers[:chainring] *= 1.3
      multipliers[:tire] *= 1.4
      multipliers[:brakepad] *= 1.3
    end

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

  def riding_environment
    {
      terrain: terrain_description,
      weather: weather_description,
      particulate: particulate_description
    }
  end

  def maintenance_recommendations
    limits = adjusted_wear_limits
    recommendations = []

    recommendations << "Chain needs replacement" if chain&.kilometres.to_i > limits[:chain]
    recommendations << "Cassette needs inspection" if cassette&.kilometres.to_i > limits[:cassette]
    recommendations << "Chainring needs inspection" if chainring&.kilometres.to_i > limits[:chainring]

    tires.each_with_index do |tire, index|
      recommendations << "Tire #{index + 1} needs replacement" if tire.kilometres.to_i > limits[:tire]
    end

    brakepads.each_with_index do |pad, index|
      recommendations << "Brake pad #{index + 1} needs inspection" if pad.kilometres.to_i > limits[:brakepad]
    end

    recommendations
  end

  def component_status
    limits = adjusted_wear_limits

    {
      bicycle: {
        kilometres: kilometres,
        lifetime_kilometres: lifetime_kilometres,
        last_maintenance: last_maintenance_date,
        riding_environment: riding_environment
      },
      chain: chain ? {
        kilometres: chain.kilometres,
        wear_limit: limits[:chain],
        wear_percentage: (chain.kilometres / limits[:chain].to_f * 100).round
      } : nil,
      cassette: cassette ? {
        kilometres: cassette.kilometres,
        wear_limit: limits[:cassette],
        wear_percentage: (cassette.kilometres / limits[:cassette].to_f * 100).round
      } : nil,
      chainring: chainring ? {
        kilometres: chainring.kilometres,
        wear_limit: limits[:chainring],
        wear_percentage: (chainring.kilometres / limits[:chainring].to_f * 100).round
      } : nil,
      tires: tires.map { |t| {
        kilometres: t.kilometres,
        wear_limit: limits[:tire],
        wear_percentage: (t.kilometres / limits[:tire].to_f * 100).round
      } },
      brakepads: brakepads.map { |b| {
        kilometres: b.kilometres,
        wear_limit: limits[:brakepad],
        wear_percentage: (b.kilometres / limits[:brakepad].to_f * 100).round
      } }
    }
  end

  private

  def terrain_description
    case terrain
    when "flat" then "Flat terrain"
    when "hilly" then "Hilly terrain"
    when "mountainous" then "Mountainous terrain"
    else "Unknown terrain"
    end
  end

  def weather_description
    case weather
    when "dry" then "Dry conditions"
    when "mixed" then "Mixed weather conditions"
    when "wet" then "Wet conditions"
    else "Unknown weather conditions"
    end
  end

  def particulate_description
    case particulate
    when "low" then "Low particulate"
    when "medium" then "Medium particulate"
    when "high" then "High particulate"
    else "Unknown particulate level"
    end
  end
end
