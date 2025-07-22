class Api::V1::ChainringsController < Api::V1::ComponentsController
  private

  def component_class
    Api::V1::Chainring
  end
end
