class Api::V1::CassettesController < Api::V1::ComponentsController
  private

  def component_class
    Api::V1::Cassette
  end
end
