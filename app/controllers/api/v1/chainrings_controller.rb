class Api::V1::ChainringsController < ApplicationController
  before_action :set_bicycle
  before_action :set_chainring, only: %i[show update destroy]

  def show
    authorize @chainring
    render json: @chainring, serializer: ::Api::V1::ChainringSerializer
  end

  def create
    @chainring = @bicycle.build_chainring(chainring_params)
    authorize @chainring

    if @chainring.save
      render json: @chainring, status: :created, serializer: ::Api::V1::ChainringSerializer
    else
      render json: @chainring.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @chainring
    if @chainring.update(chainring_params)
      render json: @chainring, serializer: ::Api::V1::ChainringSerializer
    else
      render json: @chainring.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @chainring
    @chainring.destroy
    head :no_content
  end

  private

  def set_bicycle
    @bicycle = Bicycle.find(params[:bicycle_id])
  end

  def set_chainring
    @chainring = @bicycle.chainring
  end

  def chainring_params
    params.require(:chainring).permit(:brand, :model)
  end
end
