class Api::V1::BrakepadsController < Api::V1::ComponentsController
  private

  def component_class
    Brakepad
  end

  def component_serializer
    ::Api::V1::BrakepadSerializer
  end
end
