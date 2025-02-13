class Api::V1::CassettesController < ApplicationController
  before_action :set_cassette, only: %i[show update destroy]

  def show
    authorize @cassette
    render json: @cassette, serializer: ::Api::V1::CassetteSerializer
  end

  def create
    @cassette = Cassette.new(cassette_params)
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

  def set_cassette
    @cassette = Cassette.find(params[:id])
  end

  def cassette_params
    params.require(:cassette).permit(:brand, :model, :bicycle_id)
  end
end
