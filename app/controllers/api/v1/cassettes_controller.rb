class Api::V1::CassettesController < ApplicationController
  before_action :set_bicycle
  before_action :set_cassette, only: %i[show update destroy]

  def show
    authorize @cassette
    render json: @cassette, serializer: ::Api::V1::CassetteSerializer
  end

  def create
    @cassette = @bicycle.build_cassette(cassette_params)
    authorize @cassette

    if @cassette.save
      render json: @cassette, status: :created, serializer: ::Api::V1::CassetteSerializer
    else
      render json: @cassette.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @cassette
    if @cassette.update(cassette_params)
      render json: @cassette, serializer: ::Api::V1::CassetteSerializer
    else
      render json: @cassette.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @cassette
    @cassette.destroy
    head :no_content
  end

  private

  def set_bicycle
    @bicycle = Bicycle.find(params[:bicycle_id])
  end

  def set_cassette
    @cassette = @bicycle.cassette
  end

  def cassette_params
    params.require(:cassette).permit(:brand, :model)
  end
end
