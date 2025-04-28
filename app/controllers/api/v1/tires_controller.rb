class Api::V1::TiresController < Api::V1::ComponentsController
  private

  def component_class
    Tire
  end

  def component_serializer
    ::Api::V1::ComponentSerializer
  end
end
