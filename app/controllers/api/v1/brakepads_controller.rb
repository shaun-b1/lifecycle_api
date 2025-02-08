class Api::V1::BrakepadsController < ApplicationController
  def create
    @bicycle = Bicycle.find(params[:bicycle_id])
    @brakepad = @bicycle.brakepads.build(brakepad_params)

    if @brakepad.save
      render json: @brakepad, status: :created, serializer: ::Api::V1::BrakepadSerializer
    else
      render json: @brakepad.errors, status: :unprocessable_entity
    end
  end

  private

  def brakepad_params
    params.require(:brakepad).permit(:brand, :kilometres)
  end
end
