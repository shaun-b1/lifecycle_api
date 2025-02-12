class Api::V1::BicyclesController < ApplicationController
  before_action :set_bicycle, only: %i[show update destroy]

  def index
    @bicycles = policy_scope(Bicycle.includes(:chain, :cassette, :chainring, :tires, :brakepads))
    render json: @bicycles, each_serializer: ::Api::V1::BicycleSerializer
  end

  def show
    authorize @bicycle
    render json: @bicycle, serializer: ::Api::V1::BicycleSerializer
  end

  def create
    @bicycle = Bicycle.new(bicycle_params)
    @bicycle.user = current_user
    authorize @bicycle

    if @bicycle.save
      render json: @bicycle, status: :created, serializer: ::Api::V1::BicycleSerializer
    else
      render json: @bicycle.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @bicycle
    if @bicycle.update(bicycle_params)
      render json: @bicycle, serializer: ::Api::V1::BicycleSerializer
    else
      render json: @bicycle.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @bicycle
    @bicycle.destroy
    head :no_content
  end

  private

  def set_bicycle
    @bicycle = Bicycle.includes(:chain, :cassette, :chainring, :tires, :brakepads).find(params[:id])
  end

  def bicycle_params
    params.require(:bicycle).permit(:name, :brand, :model, :kilometres)
  end
end
