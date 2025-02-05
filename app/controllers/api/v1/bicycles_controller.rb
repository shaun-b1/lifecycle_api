class Api::V1::BicyclesController < ApplicationController
  before_action :set_bicycle, only: %i[ show update destroy ]


  def show
    render json: @bicycle
  end

  def create
    @bicycle = Bicycle.new(bicycle_params)

    if @bicycle.save
      render json: @bicycle, status: :created
    else
      render json: @bicycle.errors, status: :unprocessable_entity
    end
  end

  def update
    if @bicycle.update(bicycle_params)
      render json: @bicycle
    else
      render json: @bicycle.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @bicycle.destroy
    head :no_content
  end

  private

  def set_bicycle
    @bicycle = Bicycle.find(params[:id])
  end

  def bicycle_params
    params.require(:bicycle).permit(:name, :brand, :model, :kilometers, :user_id)
  end
end
