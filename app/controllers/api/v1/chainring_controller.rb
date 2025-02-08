class Api::V1::ChainringController < ApplicationController
  def create
    @bicycle = Bicycle.find(params[:bicycle_id])
    @chainring = @bicycle.build_chainring(chainring_params)

    if @chainring.save
      render json: @chainring, status: :created, serializer: ::Api::V1::ChainringSerializer
    else
      render json: @chainring.errors, status: :unprocessable_entity
    end
  end

  private

  def chainring_params
    params.require(:chainring).permit(:brand, :kilometres)
  end
end
