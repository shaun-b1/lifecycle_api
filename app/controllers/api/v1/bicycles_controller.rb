class Api::V1::BicyclesController < ApplicationController
  include Api::V1::CrudOperations
  private

  def resource_class
    Bicycle
  end

  def resource_serializer
    ::Api::V1::BicycleSerializer
  end

  def resource_params
    params.require(:bicycle).permit(:name, :brand, :model, :kilometres)
  end

  def find_resource
    resource_class.includes(:chain, :cassette, :chainring, :tires, :brakepads).find(params[:id])
  end

  def build_resource(attributes)
    resource = super
    resource.user = current_user
    resource
  end
end
