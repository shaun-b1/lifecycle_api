class Api::V1::BicyclesController < ApplicationController
  include Api::V1::CrudOperations

  def record_ride
    @bicycle = find_resource
    authorize @bicycle

    distance = params[:distance].to_f
    notes = params[:notes]

    begin
      RideRecordingService.record(@bicycle, distance, notes)

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

    begin
      maintenance_options = build_maintenance_options

      MaintenanceService.record_maintenance(@bicycle, maintenance_options)

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
    params.require(:bicycle).permit(:name, :brand, :model, :kilometres, :terrain, :weather, :particulate)
  end

  def find_resource
    resource_class.includes(:chain, :cassette, :chainring, :tires, :brakepads).find(params[:id])
  end

  def build_resource(attributes)
    resource = super
    resource.user = current_user
    resource
  end

  def build_maintenance_options
    options = {}

    options[:notes] = params[:notes] if params[:notes].present?

    if params[:full_service] == true || params[:full_service] == "true"
      options[:full_service] = true
      options[:default_brand] = params[:default_brand]
      options[:default_model] = params[:default_model]
      options[:exceptions] = format_exceptions(params[:exceptions]) if params[:exceptions]
    end

    if params[:replacements].present?
      options[:replacements] = format_replacements(params[:replacements])
    end

    options
  end

  def format_exceptions(exceptions_params)
    formatted = {}

    exceptions_params.each do |component_type, specs|
      case component_type.to_s
      when "tires", "brakepads"
        formatted[component_type.to_sym] = Array(specs).map do |spec|
          { brand: spec[:brand], model: spec[:model] }
        end
      else
        formatted[component_type.to_sym] = { brand: spec[:brand], model: spec[:model] }
      end
    end

    formatted
  end

  def format_replacements(replacement_params)
    formatted = {}

    replacement_params.each do |component_type, specs|
      case component_type.to_s
      when "tires", "brakepads"
        formatted[component_type.to_sym] = Array(specs).map do |spec|
          { brand: spec[:brand], model: spec[:model] }
        end
      else
        formatted[component_type.to_sym] = { brand: spec[:brand], model: spec[:model] }
      end
    end

    formatted
  end
end
