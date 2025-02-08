class Api::V1::TiresController < ApplicationController
  def create
    @bicycle = Bicycle.find(params[:bicycle_id])
    @tire = @bicycle.tires.build(tire_params)

    if @tire.save
      render json: @tire, status: :created, serializer: ::Api::V1::TireSerializer
    else
      render json: @tire.errors, status: :unprocessable_entity
    end
  end

  private

  def tire_params
    params.require(:tire).permit(:brand, :kilometres)
  end
end
