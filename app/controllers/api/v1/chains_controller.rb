class Api::V1::ChainController < ApplicationController
  def create
    @bicycle = Bicycle.find(params[:bicycle_id])
    @chain = @bicycle.build_chain(chain_params)

    if @chain.save
      render json: @chain, status: :created
    else
      render json: @chain.errors, status: :unprocessable_entity
    end
  end

  private

  def chain_params
    params.require(:chain).permit(:brand, :kilometres)
  end
end
