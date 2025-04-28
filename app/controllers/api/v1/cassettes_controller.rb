class Api::V1::CassettesController < Api::V1::ComponentsController
  private

  def component_class
    Cassette
  end

  def component_serializer
    ::Api::V1::ComponentSerializer
  end
end
