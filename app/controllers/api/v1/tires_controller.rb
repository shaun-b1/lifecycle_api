class Api::V1::TiresController < ApplicationController
  before_action :set_tire, only: %i[show update destroy]

  def show
    authorize @tire
    render json: @tire, serializer: ::Api::V1::TireSerializer
  end

  def create
    @tire = Tire.new(tire_params)
    authorize @tire

    if @tire.save
      render json: @tire, status: :created, serializer: ::Api::V1::TireSerializer
    else
      render json: @tire.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @tire
    if @tire.update(tire_params)
      render json: @tire, serializer: ::Api::V1::TireSerializer
    else
      render json: @tire.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @tire
    @tire.destroy
    head :no_content
  end

  private

  def set_tire
    @tire = Tire.find(params[:id])
  end

  def tire_params
    params.require(:tire).permit(:brand, :kilometres, :bicycle_id)
  end
end
