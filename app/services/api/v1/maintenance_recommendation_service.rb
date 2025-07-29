class Api::V1::MaintenanceRecommendationService
  def initialize(bicycle, wear_limits)
    @bicycle = bicycle
    @wear_limits = wear_limits
  end

  def recommendations
    recommendations = []

    check_chain(recommendations)
    check_cassette(recommendations)
    check_chainring(recommendations)
    check_tires(recommendations)
    check_brakepads(recommendations)

    recommendations
  end

  private

  attr_reader :bicycle, :wear_limits

  def check_chain(recommendations)
    return unless bicycle.chain

    if bicycle.chain.kilometres.to_i > wear_limits[:chain]
      recommendations << "Chain needs replacement"
    end
  end

  def check_cassette(recommendations)
    return unless bicycle.cassette

    if bicycle.cassette.kilometres.to_i > wear_limits[:cassette]
      recommendations << "Cassette needs inspection"
    end
  end

  def check_chainring(recommendations)
    return unless bicycle.chainring

    if bicycle.chainring.kilometres.to_i > wear_limits[:chainring]
      recommendations << "Chainring needs inspection"
    end
  end

  def check_tires(recommendations)
    bicycle.tires.each_with_index do |tire, index|
      if tire.kilometres.to_i > wear_limits[:tire]
        recommendations << "Tire #{index + 1} needs replacement"
      end
    end
  end

  def check_brakepads(recommendations)
    bicycle.brakepads.each_with_index do |pad, index|
      if pad.kilometres.to_i > wear_limits[:brakepad]
        recommendations << "Brake pad #{index + 1} needs inspection"
      end
    end
  end
end