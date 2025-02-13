class Api::V1::BrakepadsController < ApplicationController
  before_action :set_brakepad, only: %i[show update destroy]

  def show
    authorize @brakepad
    render json: @brakepad, serializer: ::Api::V1::BrakepadSerializer
  end

  def create
    @brakepad = Brakepad.new(brakepad_params)
    authorize @brakepad

    if @brakepad.save
      render json: @brakepad, status: :created, serializer: ::Api::V1::BrakepadSerializer
    else
      render json: @brakepad.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @brakepad
    if @brakepad.update(brakepad_params)
      render json: @brakepad, serializer: ::Api::V1::BrakepadSerializer
    else
      render json: @brakepad.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @brakepad
    @brakepad.destroy
    head :no_content
  end

  private

  def set_brakepad
    @brakepad = Brakepad.find(params[:id])
  end

  def brakepad_params
    params.require(:brakepad).permit(:brand, :kilometres, :bicycle_id)
  end
end
