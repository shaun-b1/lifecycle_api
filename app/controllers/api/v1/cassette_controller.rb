class Api::V1::CassettesController < ApplicationController
  def create
    @bicycle = Bicycle.find(params[:bicycle_id])
    @cassette = @bicycle.build_cassette(cassette_params)

    if @cassette.save
      render json: @cassette, status: :created, serializer: ::Api::V1::CassetteSerializer
    else
      render json: @cassette.errors, status: :unprocessable_entity
    end
  end

  private

  def cassette_params
    params.require(:cassette).permit(:brand, :kilometres)
  end
end
