class Api::V1::BrakepadsController < Api::V1::ComponentsController
  private

  def component_class
    Brakepad
  end
end
