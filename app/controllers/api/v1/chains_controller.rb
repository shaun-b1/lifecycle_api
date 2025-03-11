class Api::V1::ChainsController < Api::V1::ComponentsController
  private

  def component_class
    Chain
  end

  def component_serializer
    ::Api::V1::ChainSerializer
  end
end
