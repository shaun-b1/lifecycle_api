class Api::V1::ComponentStatusGenerator
  def initialize(bicycle, wear_limits, riding_environment)
    @bicycle = bicycle
    @wear_limits = wear_limits
    @riding_environment = riding_environment
  end

  def status
    {
      bicycle: bicycle_status,
      chain: component_status(bicycle.chain, :chain),
      cassette: component_status(bicycle.cassette, :cassette),
      chainring: component_status(bicycle.chainring, :chainring),
      tires: tires_status,
      brakepads: brakepads_status
    }
  end

  private

  attr_reader :bicycle, :wear_limits, :riding_environment

  def bicycle_status
    {
      kilometres: bicycle.kilometres,
      lifetime_kilometres: bicycle.lifetime_kilometres,
      last_maintenance: bicycle.last_maintenance_date,
      riding_environment: riding_environment.to_hash
    }
  end

  def component_status(component, component_type)
    return nil unless component

    limit = wear_limits[component_type]
    kilometres = component.kilometres

    {
      kilometres: kilometres,
      wear_limit: limit,
      wear_percentage: (kilometres / limit.to_f * 100).round
    }
  end

  def tires_status
    bicycle.tires.map do |tire|
      {
        kilometres: tire.kilometres,
        wear_limit: wear_limits[:tire],
        wear_percentage: (tire.kilometres / wear_limits[:tire].to_f * 100).round
      }
    end
  end

  def brakepads_status
    bicycle.brakepads.map do |brakepad|
      {
        kilometres: brakepad.kilometres,
        wear_limit: wear_limits[:brakepad],
        wear_percentage: (brakepad.kilometres / wear_limits[:brakepad].to_f * 100).round
      }
    end
  end
end