class Api::V1::ChainringsController < Api::V1::ComponentsController
  private

  def component_class
    Chainring
  end

  def component_serializer
    ::Api::V1::ChainringSerializer
  end
end
