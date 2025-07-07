class Api::V1::BicyclesController < ApplicationController
  include Api::V1::CrudOperations

  def record_ride
    @bicycle = find_resource
    authorize @bicycle

    distance = params[:distance].to_f
    notes = params[:notes]

    begin
      Api::V1::RideRecordingService.record(@bicycle, distance, notes)

      response = Api::V1::ResponseService.success(
        ActiveModelSerializers::SerializableResource.new(
          @bicycle.reload,
          serializer: resource_serializer
        ).as_json,
        "Ride recorded successfully"
      )

      render response
    rescue Api::V1::Errors::ApiError => e
      render json: e.to_hash, status: e.status
    end
  end

  def record_maintenance
    @bicycle = find_resource
    authorize @bicycle

    notes = params[:notes]
    components = Array(params[:components])

    begin
      if params[:full_service].present? && params[:full_service] == "true"
        Api::V1::MaintenanceService.record_full_service(@bicycle, notes)
      else
        Api::V1::MaintenanceService.record_bicycle_maintenance(@bicycle, components, notes)
      end

      response = Api::V1::ResponseService.success(
        ActiveModelSerializers::SerializableResource.new(
          @bicycle.reload,
          serializer: resource_serializer
        ).as_json,
        "Maintenance recorded successfully"
      )

      render response
    rescue Api::V1::Errors::ApiError => e
      render json: e.to_hash, status: e.status
    end
  end

  private

  def resource_class
    Bicycle
  end

  def resource_serializer
    ::Api::V1::BicycleSerializer
  end

  def resource_params
    params.require(:bicycle).permit(:name,
      :brand,
      :model,
      :kilometres,
      :terrain,
      :weather,
      :particulate)
  end

  def find_resource
    resource_class.includes(:chain, :cassette, :chainring, :tires, :brakepads).find(params[:id])
  end

  def build_resource(attributes)
    resource = super
    resource.user = current_user
    resource
  end
end
