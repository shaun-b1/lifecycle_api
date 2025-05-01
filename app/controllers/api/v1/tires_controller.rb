class Api::V1::TiresController < Api::V1::ComponentsController
  private

  def component_class
    Tire
  end
end
