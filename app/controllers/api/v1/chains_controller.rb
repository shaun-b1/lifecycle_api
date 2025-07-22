class Api::V1::ChainsController < Api::V1::ComponentsController
  private

  def component_class
    Api::V1::Chain
  end
end
