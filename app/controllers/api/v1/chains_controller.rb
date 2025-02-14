class Api::V1::ChainsController < ApplicationController
  before_action :set_bicycle
  before_action :set_chain, only: %i[show update destroy]

  def show
    authorize @chain
    render json: @chain, serializer: ::Api::V1::ChainSerializer
  end

  def create
    @chain = @bicycle.build_chain(chain_params)
    authorize @chain

    if @chain.save
      render json: @chain, status: :created, serializer: ::Api::V1::ChainSerializer
    else
      render json: @chain.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @chain
    if @chain.update(chain_params)
      render json: @chain, serializer: ::Api::V1::ChainSerializer
    else
      render json: @chain.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @chain
    @chain.destroy
    head :no_content
  end

  private

  def set_bicycle
    @bicycle = Bicycle.find(params[:bicycle_id])
  end

  def set_chain
    @chain = @bicycle.chain
  end

  def chain_params
    params.require(:chain).permit(:brand, :kilometres)
  end
end
